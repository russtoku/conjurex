(local {: autoload} (require :nfnl.module))
(local a (autoload :nfnl.core))
(local nvim (autoload :conjure.aniseed.nvim)) ;; FIXME: Replace with vim.api.nvim_*.
(local str (autoload :nfnl.string))

(local version "conjurex")

;; For the execution of external processes through Neovim's terminal
;; integration. This module only cares about checking for some required program
;; and then executing it with some arguments in a terminal buffer. It doesn't
;; manage the lifecycle past that point, so it's very much on it's own after it
;; begins.
;;
;; The initial use case for this is to start a babashka REPL for Clojure files
;; if no nREPL connection can be established.

(fn executable? [cmd]
  "Check if the given program name can be found on the system. If you give it a
  full command with arguments it'll just check the first word."
  (= 1 (vim.fn.executable (a.first (str.split cmd "%s+")))))

(fn running? [proc]
  (if proc
    (. proc :running?)
    false))

(local state {:jobs {}})

(fn on-exit [job-id]
  (let [proc (. state.jobs job-id)]
    (when (running? proc)
      (a.assoc proc :running? false)
      (tset state.jobs proc.job-id nil)
      (pcall vim.api.nvim_buf_delete proc.buf {:force true})
      (let [on-exit (a.get-in proc [:opts :on-exit])]
        (when on-exit
          (on-exit proc))))))

;; TODO When Neovim 0.5 is stable we can pass a Lua function across this
;; boundary. Until then, yucky gross stuff.
;; This is absolutely horrible, but there's no other way to do it if I want to
;; support anything < 0.5 for now.
;; So rather than just using a closure to pass the proc into the exit fn, I
;; have to go through a VimL function that relies on a global table of jobs to
;; look the data back up.
(nvim.ex.function_
  (str.join
    "\n"
    ["ConjureProcessOnExit(...)"
     "call luaeval(\"require('conjure.process')['on-exit'](unpack(_A))\", a:000)"
     "endfunction"]))

(fn execute [cmd opts]
  (let [win (vim.api.nvim_tabpage_get_win 0)
        original-buf (vim.api.nvim_win_get_buf win)
        term-buf (vim.api.nvim_create_buf (not (?. opts :hidden?)) true)
        proc {:cmd cmd :buf term-buf
              :running? true
              :opts opts}
        job-id (do
                 (vim.api.nvim_win_set_buf win term-buf)
                 (vim.fn.termopen cmd {:on_exit "ConjureProcessOnExit"}))]
    (match job-id
      0 (error "invalid arguments or job table full")
      -1 (error (.. "'" cmd "' is not executable")))
    (vim.api.nvim_win_set_buf win original-buf)
    (tset state.jobs job-id proc)
    (a.assoc proc :job-id job-id)))


(fn stop [proc]
  (when (running? proc)
    (vim.fn.jobstop proc.job-id)
    (on-exit proc.job-id))
  proc)

{: executable?
 : execute
 : on-exit
 : running?
 : stop
 : version}
