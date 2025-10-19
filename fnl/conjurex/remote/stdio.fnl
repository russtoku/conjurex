(local {: autoload : define} (require :nfnl.module))
(local core (autoload :nfnl.core))
(local client (autoload :conjure.client))
(local log (autoload :conjurex.log))
(local str (autoload :nfnl.string))
(local uv vim.loop)

(local M (define :conjurex.remote.stdio))

(set M.version "conjurex.remote.stdio")

(fn parse-prompt [s pat]
  (if (s:find pat)
    (values true (s:gsub pat ""))
    (values false s)))

(fn M.parse-cmd [x]
  "Returns cmd and args if x is a table. Else if x is a string recursively call
  parse-cmd after splitting x into words."
  (if
    (core.table? x)
    {:cmd (core.first x)
     :args (core.rest x)}

    (core.string? x)
    (M.parse-cmd (str.split x "%s"))))

(fn extend-env [vars]
  "Return a list of k=v environment variables with vars table's entries added."
  (->> (core.merge
         (vim.fn.environ)
         vars)
       (core.kv-pairs)
       (core.map
         (fn [[k v]]
           (.. k "=" v)))))

(fn M.start [opts]
  "Starts an external REPL and gives you hooks to send code to it and read
  responses back out. Tying an input to a result is near enough impossible
  through this stdio medium, so it's a best effort.

  * opts.prompt-pattern: Identify result boundaries such as '> '.
  * opts.cmd: Command to run to start the REPL.
  * opts.args: Arguments to pass to the REPL.
  * opts.on-success: Function to run when a REPL process is successfully spawned.
  * opts.on-error: Called with an error string when we receive a true error from the process.
  * opts.delay-stderr-ms: If passed, delays the call to on-error for this many milliseconds. This
                          is a workaround for clients like python whose prompt on stderr sometimes
                          arrives before the previous command's output on stdout.
  * opts.on-stray-output: Called with stray output that don't match up to a callback.
  * opts.on-exit: Called on exit with the code and signal."
  (log.dbg M.version ": M.start: opts>" (core.pr-str opts) "<")
  (let [stdin (uv.new_pipe false)
        stdout (uv.new_pipe false)
        stderr (uv.new_pipe false)]

    (var repl {:queue []
               :current nil})

    (fn destroy []
      (log.dbg M.version ": M.start: destroy")
      ;; https://teukka.tech/vimloop.html
      (pcall #(stdout:read_stop))
      (pcall #(stderr:read_stop))
      (pcall #(stdout:close))
      (pcall #(stderr:close))
      (pcall #(stdin:close))
      (when repl.handle
        (pcall #(uv.process_kill repl.handle uv.constants.SIGINT))
        (pcall #(repl.handle:close))
        (log.dbg M.version ": destroy: sent SIGINT to handle>" (core.pr-str repl.handle) "<"))
      nil)

    (fn on-exit [code signal]
      (log.dbg M.version ": on-exit: code>" (core.pr-str code) "<\nsignal>" (core.pr-str signal) "<")
      (destroy)
      (client.schedule opts.on-exit code signal))

    (fn next-in-queue []
      "Remove the head of repl.queue and send it to the REPL."
      (log.dbg M.version ": next-in-queue: repl.queue>" (core.pr-str repl.queue) "<")
      (let [next-msg (core.first repl.queue)]
        (when (and next-msg (not repl.current))
          (table.remove repl.queue 1)
          (core.assoc repl :current next-msg)
          (log.dbg M.version ": send>" (core.pr-str next-msg.code) "<")
          (stdin:write next-msg.code))))

    (fn on-message [source err chunk]
      (log.dbg M.version ": receive from>" (core.pr-str source) "<\nerr>" err "<\nchunk>" (core.pr-str chunk) "<")
      (if err
        (do
          (opts.on-error err)
          (destroy))
        (when chunk
          (let [(done? result) (parse-prompt chunk opts.prompt-pattern)
                cb (core.get-in repl [:current :cb] opts.on-stray-output)] ; What is cb? Where set?
            (when cb
              (log.dbg M.version ": received from " source "\nerr>" err "<\nchunk>" (core.pr-str chunk) "<")
              (log.dbg M.version ":   err>" err "<")
              (log.dbg M.version ":   chunk>" (core.pr-str chunk) "<")
              (pcall
                #(cb {source result
                      :done? done?})))
            (when done?
              (core.assoc repl :current nil)
              (next-in-queue))))))

    (fn on-stdout [err chunk]
      (on-message :out err chunk))

    (fn on-stderr [err chunk]
      (if opts.delay-stderr-ms ; Sometimes we want the stderr to be delayed.
        (vim.defer_fn #(on-message :err err chunk) opts.delay-stderr-ms)
        (on-message :err err chunk)))

    ; The code and cb are bundled before being put into a run queue.
    ; Then the next item in the run queue is executed.
    (fn send [code cb opts]
      (table.insert
        repl.queue
        {:code code
         :cb (if (core.get opts :batch?)
               (let [msgs []]
                 (fn [msg]
                   (table.insert msgs msg)
                   (when msg.done?
                     (cb msgs))))
               cb)})
      (next-in-queue)
      nil)

    (fn send-signal [signal]
      (uv.process_kill repl.handle signal)
      nil)

    (let [{: cmd : args} (M.parse-cmd opts.cmd)
          (handle pid-or-err)
          (uv.spawn cmd {:stdio [stdin stdout stderr]
                         :args args
                         :env (extend-env
                                (core.merge!
                                  ;; Trying to disable custom readline config.
                                  ;; Doesn't work in practice but is probably close?
                                  ;; If you know how, please open a PR!
                                  {:INPUTRC "/dev/null"
                                   :TERM "dumb"}
                                  opts.env))}
                    (client.schedule-wrap on-exit))]
      (if handle
        (do
          (stdout:read_start (client.schedule-wrap on-stdout))
          (stderr:read_start (client.schedule-wrap on-stderr))
          (client.schedule #(opts.on-success))
          (core.merge!
            repl
            {:handle handle
             :pid pid-or-err
             :send send
             :opts opts
             :send-signal send-signal
             :destroy destroy}))
        (do ; no handle
          (client.schedule #(opts.on-error pid-or-err))
          (destroy))))))

M
