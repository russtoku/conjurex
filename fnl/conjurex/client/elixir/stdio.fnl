(local {: autoload : define} (require :conjure.nfnl.module))
(local core (autoload :conjure.nfnl.core))
(local client (autoload :conjure.client))
(local config (autoload :conjure.config))
(local log (autoload :conjure.log))
(local mapping (autoload :conjure.mapping))
(local stdio (autoload :conjurex.remote.stdio))
(local str (autoload :conjure.nfnl.string))

;;============================================================
;;
;; Based on https://github.com/brandonpollack23/conjure/tree/add-elixir-client
;; for https://github.com/Olical/conjure/issues/635.
;;
;; This differs from Brandon's implementation because it's based on the Scheme client,
;; conjure.client.scheme.stdio.
;;
;; Also, it is in a separate repo from Conjure as an example
;; of creating clients that are not part of the Conjure codebase. This should allow people
;; to contribute to the Conjure ecosystem without having to add to the main codebase.
;;
;;============================================================

;;------------------------------------------------------------
;; Example interaction with iex REPL:
;;
;;
;;  $ iex
;;  Erlang/OTP 28 [erts-16.0] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit] [dtrace]
;;
;;  Interactive Elixir (1.18.4) - press Ctrl+C to exit (type h() ENTER for help)
;;  iex(1)> (1)
;;  1
;;  iex(2)> add(1, 2)
;;  error: undefined function add/2 (there is no such import)
;;  └─ iex:2
;;
;;  ** (CompileError) cannot compile code (errors have been logged)
;;
;;  iex(2)> 1+ 2
;;  3
;;  iex(3)>
;;------------------------------------------------------------


(local M (define :conjurex.client.elixir.stdio))

(config.merge
  {:client
   {:elixir
    {:stdio
     {:command "iex"
      :mix_command "iex -S mix" ; not implemented yet. See TODO below.
      :prompt_pattern "iex%(%d+%)> "}}}})

(when (config.get-in [:mapping :enable_defaults])
  (config.merge
    {:client
     {:elixir
      {:stdio
       {:mapping {:start "cs"
                  :stop "cS"
                  :interrupt "ei"}}}}}))

(local cfg (config.get-in-fn [:client :elixir :stdio]))
(local state (client.new-state #(do {:repl nil})))
(set M.buf-suffix ".ex")
(set M.comment-prefix "# ")

;; This should allow using <localleader>ee on most expressions or statements.
(fn M.form-node? [node]
  (log.dbg (.. "M.form-node?: node:type = " (core.pr-str (node:type))))
  (log.dbg (.. "M.form-node?: node:parent = " (core.pr-str (node:parent))))
  (let [parent (node:parent)]
    (if (= "call" (node:type)) true
        (= "binary_operator" (node:type)) true
        (and (= "list" (node:type))
             (not (= "binary_operator" (parent:type)))) true
        (= "integer" (node:type)) true
        (= "char" (node:type)) true
        (= "sigil" (node:type)) true
        (= "float" (node:type)) true
        (= "string" (node:type)) true
        (= "tuple" (node:type)) true
        (= "identifier" (node:type)) true
        (= "unary_operator" (node:type)) true
        (= "map" (node:type)) true
        (= "nil" (node:type)) true
        (= "integer" (node:type)) true
        (= "charlist" (node:type)) true
        false)))

(fn with-repl-or-warn [f opts]
  (let [repl (state :repl)]
    (if repl
      (f repl)
      (log.append [(.. M.comment-prefix "No REPL running")]))))

(fn prep-code [s]
  (.. s "\n"))

(fn display-result [msg]
  (->> msg
       (core.map #(.. M.comment-prefix $1))
       log.append))

;; A function to clean the lines of an output message. It removes "iex:15" and
;; "..(12)>" parts of the message and any blank lines.
(fn remove_prompts [msgs]
  (->>
    (str.split msgs "\n")
    (core.filter #(not (= "" $1)))
    ; (core.filter #(core.nil? (string.find $1 "iex:%d+:")))
    (core.filter #(core.nil? (string.find $1 "iex:%d+")))
    (core.map #(string.gsub $1 "%.+%(%d+%)> +" ""))))

;; # debug: M.unbatch: msgs=[{:done? true↵  :out "** (BadBooleanError) expected a boolean on left-side of \"and\", got: 1↵    iex:15: (file)↵"}]
(fn M.unbatch [msgs]
  (log.dbg (.. "M.unbatch: msgs=" (core.pr-str msgs)))
  ;; Pass array to a series of functions that operate on the array.
  ;; Map a function to split each element of the array
  {:out (->> msgs
             (core.map #(or (core.get $1 :out) (core.get $1 :err)))
             ; (core.map #(remove_secondary_prompt $1))
             (core.map #(remove_prompts $1))
             (core.map #(str.join "\n" $1))
             (str.join))})

;; # debug: format-msg: msg={:out "3↵"}
(fn M.format-msg [msg]
  (log.dbg (.. "M.format-msg: msg=" (core.pr-str msg)))
  (->> (-> msg
           (core.get :out)
           (str.split "\n"))
       (core.filter #(not (str.blank? $1)))
       (core.map (fn [line] line))))

(fn M.eval-str [opts]
  (log.dbg (.. "M.eval-str: opts=" (core.pr-str opts)))
  (with-repl-or-warn
    (fn [repl]
      (repl.send
        ; (.. opts.code "\n")
        (prep-code opts.code )
        (fn [msgs]
          (let [msgs (-> msgs M.unbatch M.format-msg)]
            (log.dbg (.. "M.eval-str: in cb: msgs=" (core.pr-str msgs)))
            ; (opts.on-result (core.last msgs))
            (opts.on-result (str.join "\n" msgs))
            (log.append msgs)))
        {:batch? true}))))

(fn M.eval-file [opts]
  (M.eval-str (core.assoc opts :code (core.slurp opts.file-path))))

(fn display-repl-status [status]
  (log.append
    [(.. M.comment-prefix
         (cfg [:command])
         " (" (or status "no status") ")")]
    {:break? true}))

(fn M.stop []
  (let [repl (state :repl)]
    (when repl
      (repl.destroy)
      (display-repl-status :stopped)
      (core.assoc (state) :repl nil))))

(fn M.start []
  (log.dbg (.. "start: prompt_pattern=" (cfg [:prompt_pattern])
               "cmd=" (cfg [:command])))
  (if (state :repl)
    (log.append [(.. M.comment-prefix "Can't start, REPL is already running.")
                 (.. M.comment-prefix "Stop the REPL with "
                     (config.get-in [:mapping :prefix])
                     (cfg [:mapping :stop]))]
                {:break? true})
    (core.assoc
      (state) :repl
      (stdio.start
        {:prompt-pattern (cfg [:prompt_pattern])
         ; TODO: Handle Mix projects, too. See https://github.com/brandonpollack23/conjure/blob/38188097dbca91d8f8a96bda24e259a1ee2b44f2/fnl/conjure/client/elixir/stdio.fnl#L148
         :cmd (cfg [:command])

         :on-success
         (fn []
           ; (display-repl-status :started))
           (display-repl-status :started)
           (with-repl-or-warn
             (fn [repl]
               (repl.send
                 (prep-code ":help")
                 (fn [msgs]
                   (display-result (-> msgs M.unbatch M.format-msg)))
                 {:batch? true}))))

         :on-error
         (fn [err]
           (display-repl-status err))

         :on-exit
         (fn [code signal]
           (when (and (= :number (type code)) (> code 0))
             (log.append [(.. M.comment-prefix "process exited with code " (core.pr-str code))]))
           (when (and (= :number (type signal)) (> signal 0))
             (log.append [(.. M.comment-prefix "process exited with signal " (core.pr-str signal))]))
           (M.stop))

         :on-stray-output
         (fn [msg]
           (log.append (M.format-msg msg)))}))))

(fn M.on-exit []
  (M.stop))

(fn M.interrupt []
  (with-repl-or-warn
    (fn [repl]
      (log.append [(.. M.comment-prefix " Sending interrupt signal.")] {:break? true})
      (repl.send-signal :sigint))))

(fn M.on-load []
  (M.start))

(fn M.on-filetype []
  (mapping.buf
    :ElixirStart (cfg [:mapping :start])
    #(M.start)
    {:desc "Start the REPL"})

  (mapping.buf
    :ElixirStop (cfg [:mapping :stop])
    #(M.stop)
    {:desc "Stop the REPL"})

  (mapping.buf
    :ElixirInterrupt (cfg [:mapping :interrupt])
    #(M.interrupt)
    {:desc "Interrupt the REPL"}))

M
