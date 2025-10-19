(local {: autoload : define} (require :conjure.nfnl.module))
(local a (autoload :nfnl.core))
(local b64 (autoload :conjure.remote.transport.base64))
(local client (autoload :conjure.client))
(local config (autoload :conjure.config))
(local log (autoload :conjurex.log))
(local mapping (autoload :conjure.mapping))
(local stdio (autoload :conjurex.remote.stdio))
(local str (autoload :nfnl.string))
(local text (autoload :conjurex.text))
(local ts (autoload :conjure.tree-sitter))

(local M (define :conjurex.client.python.stdio))

(set M.version "conjurex.client.python.stdio")

(config.merge
  {:client
   {:python
    {:stdio
     {:command "python3 -iq"
      :prompt-pattern ">>> "
      :delay-stderr-ms 10}}}})

(when (config.get-in [:mapping :enable_defaults])
  (config.merge
    {:client
     {:python
      {:stdio
       {:mapping {:start "cs"
                  :stop "cS"
                  :interrupt "ei"}}}}}))

(local cfg (config.get-in-fn [:client :python :stdio]))
(local state (client.new-state #(do {:repl nil})))
(set M.buf-suffix ".py")
(set M.comment-prefix "# ")

; These types of nodes are roughly equivalent to Lisp forms.
; This should make it more intuitive to use <localLeader>ee to evaluate the
; "current form" and not be surprised that it wasn't what you thought.
(fn M.form-node?
  [node]
  (log.dbg "form-node?: node:type =" (node:type))
  (log.dbg "form-node?: node:parent =" (node:parent))
  (let [parent (node:parent)]
    (if (= "expression_statement" (node:type)) true
        (= "import_statement" (node:type)) true
        (= "import_from_statement" (node:type)) true
        (= "with_statement" (node:type)) true
        (= "decorated_definition" (node:type)) true
        (= "for_statement" (node:type)) true
        (= "call" (node:type)) true
        (and (= "class_definition" (node:type))
              (not (= "decorated_definition" (parent:type)))) true
        (and (= "function_definition" (node:type))
             (not (= "decorated_definition" (parent:type)))) true
        false)))

(fn with-repl-or-warn [f opts]
  (let [repl (state :repl)]
    (if repl
      (f repl)
      (log.append [(.. M.comment-prefix "No REPL running")
                   (.. M.comment-prefix
                       "Start REPL with "
                       (config.get-in [:mapping :prefix])
                       (cfg [:mapping :start]))]))))


; Returns whether a given expression node is an assignment expression
; An assignment expression seems to be a weird case where it does not actually
; evaluate to anything so it seems more like a statement
(fn M.is-assignment?
  [node]
  (and (= (node:child_count) 1)
       (let [child (node:child 0)]
         (= (child:type) "assignment"))))

(fn M.is-expression?
  [node]
  (and (= "expression_statement" (node:type))
       (not (M.is-assignment? node))))

; Returns whether the string passed in is a simple python
; expression or something more complicated. If it is an expression,
; it can be passed to the REPL as is.
; Otherwise, we evaluate it as a multiline string using "exec". This is a simple
; way for us to not worry about extra or missing newlines in the middle of the code
; we are trying to evaluate at the REPL.
;
; For example, this Python code:
;   for i in range(5):
;       print(i)
;   def foo():
;       print("bar")
; while valid Python code, would not work in the REPL because the REPL expects 2 newlines
; after the for loop body.
;
; In addition, this Python code:
;   for i in range(5):
;       print(i)
;
;       print(i)
; while also valid Python code, would not work in the REPL because the REPL thinks the for loop
; body is over after the first "print(i)" (because it is followed by 2 newlines).
;
; Sending statements like these as a multiline string to Python's exec seems to be a decent workaround
; for this. Another option that I have seen used in some other similar projects is sending the statement
; as a "bracketed paste" (https://cirw.in/blog/bracketed-paste) so the REPL treats the input as if it were
; "pasted", but I couldn't get this working.
(fn M.str-is-python-expr?
  [s]
  (let [parser (vim.treesitter.get_string_parser s "python")
        result (parser:parse)
        tree (a.get result 1)
        root (tree:root)]
    (and (= 1 (root:child_count))
         (M.is-expression? (root:child 0)))))

(fn get-exec-str
  [s]
  (.. "import base64\nexec(base64.b64decode('" (b64.encode s) "'))\n"))

(fn prep-code [s]
  (let [python-expr (M.str-is-python-expr? s)]
    (if python-expr
      (.. s "\n")
      (get-exec-str s))))

; If, after pressing newline, the python interpreter expects more
; input from you (as is the case after the first line of an if branch or for loop)
; the python interpreter will output "..." to show that it is waiting for more input.
; We want to detect these lines and ignore them.
; Note: This is check will yield some false positives. For example if a user evaluates
;   print("... <-- check out those dots")
; the output will be flagged as one of these special "dots" lines. This could probably
; be smarter, but will work for most normal cases for now.
(fn is-dots? [s]
  (= (string.sub s 1 3) "..."))

(fn M.format-msg [msg]
  (log.dbg (.. "M.format-msg: >> " msg "<<"))
  (->> (text.split-lines msg)
       (a.filter #(~= "" $1))
       (a.filter #(not (is-dots? $1)))))

;; FIXME: Incorrect assumption: The last line in msgs from the REPL is the return
;; value or results of "evaluating" the Python expression, variable, or
;; statement. get-console-output-msgs and get-expression-result embody this
;; assumption. Also log-repl-output makes this assumption because it calls
;; get-console-output-msgs. Additionally, eval-str calls log-repl-output.
(fn get-console-output-msgs [msgs]
  (->> (a.butlast msgs)
       (a.map #(.. M.comment-prefix "(out) " $1))))

(fn get-expression-result [msgs]
  (let [result (a.last msgs)]
    (if
      (or (a.nil? result) (is-dots? result))
      nil
      result)))

(fn get-all-console-output [msgs]
  "Return a sequential table of message lines prefixed with the comment-prefix
  and '(out)'. This is intended to be passed to the log.append function."
  (->> msgs
       (a.map #(.. M.comment-prefix "(out) " $1))))

(fn get-all-output-msgs [msgs]
  "Return the msgs in a single string. This is intended to be inserted into the
  source buffer as a comment or as virtual text."
  (str.join "\n" msgs))

; Does this join the stdout and stderr msgs?
(fn M.unbatch [msgs]
  (->> msgs
       (a.map #(or (a.get $1 :out) (a.get $1 :err)))
       (str.join "")))

(fn log-repl-output [msgs]
  (let [msgs (-> msgs M.unbatch M.format-msg)
        console-output-msgs (get-console-output-msgs msgs)
        cmd-result (get-expression-result msgs)]
    (when (not (a.empty? console-output-msgs))
      (log.append console-output-msgs))
    (when cmd-result
      (log.append [cmd-result]))))

(fn M.eval-str [opts]
  (log.dbg (.. "M.eval-str opts >> " (a.pr-str opts) "<<"))

  ;; Handle the return messages from the REPL. This is intended to be passed to
  ;; the send function of the REPL instance.
  ;; Decides what is returned as the result of an evaluation vs. printed
  ;; outpupt. For the standard Python REPL, it is the same thing.
  (fn return-handler [msgs]
    (log.dbg (.. "client.python.stdio: in return-handler; msgs>" (a.pr-str msgs) "<"))
    (let [msgs (-> msgs M.unbatch M.format-msg)
          cmd-result (get-all-output-msgs msgs)
          console-result (get-all-console-output msgs)]
      (when cmd-result
        (log.append console-result))
      (when opts.on-result ; what sets opts.on-result?
        (opts.on-result cmd-result))))

  (with-repl-or-warn
    (fn [repl]
      (repl.send
        (prep-code opts.code)
        return-handler
        {:batch? true}))))

(fn M.eval-file [opts]
  (M.eval-str (a.assoc opts :code (a.slurp opts.file-path))))

(fn M.get-help [code]
  (str.join "" ["help(" (str.trim code) ")"]))

(fn M.doc-str [opts]
  (when (M.str-is-python-expr? opts.code)
    (M.eval-str (a.assoc opts :code (M.get-help opts.code)))))

(fn display-repl-status [status]
  ( log.append
    [(.. M.comment-prefix
         (cfg [:command])
         " (" (or status "no status") ")")]
    {:break? true}))

(fn M.stop []
  (log.append [(.. M.comment-prefix " " M.version ".stop called")])
  (let [repl (state :repl)]
    (when repl
      (repl.destroy)
      (display-repl-status :stopped)
      (a.assoc (state) :repl nil))))

(set M.initialise-repl-code
  ;; We set the `__name__` to something else so `__main__` blocks aren't executed.
  (str.join
    "__name__ = '__repl__'"
    "\n"))

(fn M.start []
  (log.append [(.. M.comment-prefix "Starting Python client...")])
  (if (state :repl)
    (log.append [(.. M.comment-prefix "Can't start, REPL is already running.")
                 (.. M.comment-prefix "Stop the REPL with "
                     (config.get-in [:mapping :prefix])
                     (cfg [:mapping :stop]))]
                {:break? true})
    (if (not (pcall #(ts.add-language "python")))
      (log.append [(.. M.comment-prefix "(error) The python client requires a python treesitter parser in order to function.")
                   (.. M.comment-prefix "(error) See https://github.com/nvim-treesitter/nvim-treesitter")
                   (.. M.comment-prefix "(error) for installation instructions.")])
      (a.assoc  ; Start a REPL and add it to our client state.
        (state) :repl
        (stdio.start ; stdio.start takes a table of opts to create a REPL process.
          {:prompt-pattern (cfg [:prompt-pattern])
           :cmd (cfg [:command])
           :delay-stderr-ms (cfg [:delay-stderr-ms])

           :on-success
           (fn []
             (display-repl-status :started
              (with-repl-or-warn
               (fn [repl]
                 (repl.send
                   (prep-code M.initialise-repl-code)
                   (fn [msgs] nil)
                   nil)))))

           :on-error
           (fn [err]
             (display-repl-status err))

           :on-exit
           (fn [code signal]
             ;; FIXME: The log statements don't appear in the log file.
             (log.append [(.. M.comment-prefix "on-exit: code=>" code "<, signal=" signal)])
             (when (and (= :number (type code)) (> code 0))
               (log.append [(.. M.comment-prefix "process exited with code " code)]))
             (when (and (= :number (type signal)) (> signal 0))
               (log.append [(.. M.comment-prefix "process exited with signal " signal)]))
             (M.stop))

           :on-stray-output
           (fn [msg]
             (log.dbg (-> [msg] M.unbatch M.format-msg) {:join-first? true}))})))))

(fn M.on-exit []
  (log.append [(.. M.version  ".on-exit called")])
  (M.stop))

(fn M.interrupt []
  (with-repl-or-warn
    (fn [repl]
      (log.append [(.. M.comment-prefix " Sending interrupt signal.")] {:break? true})
      (repl.send-signal :sigint))))

(fn M.on-load []
  ;; Start up REPL only if g.conjure#client_on_load is v:true.
  (when (config.get-in [:client_on_load])
    (M.start)))

(fn M.on-filetype []
  (mapping.buf
    :PythonStart (cfg [:mapping :start])
    M.start
    {:desc "Start the Python REPL"})

  (mapping.buf
    :PythonStop (cfg [:mapping :stop])
    M.stop
    {:desc "Stop the Python REPL"})

  (mapping.buf
    :PythonInterrupt (cfg [:mapping :interrupt])
    M.interrupt
    {:desc "Interrupt the current evaluation"}))

M
