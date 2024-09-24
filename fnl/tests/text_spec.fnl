(local {: describe : it} (require :plenary.busted))
(local assert (require :luassert.assert))
(local text (require :conj-rt.text))

(describe "conj-rt.text"
  (fn []
    (it "chars splits string into characters"
      (fn []
        (let [str "It's so much @%^&*\n () ?./\\"
              chs ["I" "t" "'" "s" " " "s"
                   "o" " " "m" "u" "c" "h"
                   " " "@" "%" "^" "&" "*"
                   "\n" " " "(" ")" " " "?"
                   "." "/" "\\"]]
          (assert.same chs (text.chars str)))))

    (let [xs "The rain in Spain falls main on #@$%^!&*\"-+="
          keep-left "The rain in S..."
          keep-right "... #@$%^!&*\"-+="]
      (it "left-sample keeps the left side"
        (fn []
           (assert.same keep-left (text.left-sample xs 14))))

      (it "right-sample keeps the right side"
        (fn []
           (assert.same keep-right (text.right-sample xs 14))))
    )

    (let [str1 "Sunshine on my shoulder\nmakes me happy!"
          str2 "Sunshine on my shoulder\n"]
      (it "ends-with doesn't find character at end of string"
        (fn []
          (assert.is_not_true (text.ends-with str1 "\n"))))

      (it "ends-with finds character at end of string"
        (fn []
          (assert.is_true (text.ends-with str2 "\n"))))

      (it "ends-with finds sub-string at end of string"
        (fn []
          (assert.is_true (text.ends-with str1 "me happy!"))))

      (it "first-and-last-chars returns first and last character from string"
        (fn []
          (assert.equals "S!" (text.first-and-last-chars str1))))

      (it "trailing-newline? returns nil from string without trailing newline"
        (fn []
          (assert.equals nil (text.trailing-newline? str1))))

      (it "trailing-newline? returns newline from string with trailing newline"
        (fn []
          (assert.equals "\n" (text.trailing-newline? str2))))

      (it "trim-last-newline returns 0 from string without trailing newline"
        (fn []
          (let [(str count) (text.trim-last-newline str1)]
            (assert.equals str1 str)
            (assert.equals 0 count))))

      (it "trim-last-newline returns 1 when it strips newline from string"
        (fn []
          (let [(str count) (text.trim-last-newline str2)]
            (assert.equals "Sunshine on my shoulder" str)
            (assert.equals 1 count))))

      (describe "starts-with"
        (fn []
          (it "a single character"
            (fn []
              (assert.is_true (text.starts-with str1 "S"))))

          (it "a word"
            (fn []
              (assert.is_true (text.starts-with str1 "Sunshine"))))

          (it "two words"
            (fn []
              (assert.is_true (text.starts-with str1 "Sunshine on"))))

          (it "doesn't start with a string"
            (fn []
              (assert.is_not_true (text.starts-with str1 "Math"))))))

    (it "prefixed-lines splits and prefixes all lines"
      (fn []
        (assert.same ["(out)Sunshine on my shoulder" "(out)makes me happy!"]
                     (text.prefixed-lines str1 "(out)"))))

    (it "prefixed-lines splits and prefixes all lines except the first"
      (fn []
        (assert.same ["Sunshine on my shoulder" "(out)makes me happy!"]
                     (text.prefixed-lines str1 "(out)" {:skip-first? true})))))

    (it "upper-first returns string with first character capitalized"
      (fn []
        (assert.equals "Sunshine" (text.upper-first "sunshine"))))

    (describe "split-lines"
      (fn []
        (it "empty string returns list of one empty string"
          (fn []
            (assert.same [""] (text.split-lines ""))))

        (it "string without newlines returns list of one string"
          (fn []
            (assert.same ["Sunshine on"] (text.split-lines "Sunshine on"))))

        (it "string with only newline returns list of two empty strings"
          (fn []
            (assert.same  ["" ""] (text.split-lines "\n"))))

        (it "string with newline returns list of two strings"
          (fn []
            (assert.same ["Sunshine on" " my shoulder"]
                         (text.split-lines "Sunshine on\n my shoulder"))))

        (it "string with two newlines returns list of three strings"
          (fn []
            (assert.same ["Sunshine on" " my shoulder" ""]
                         (text.split-lines "Sunshine on\n my shoulder\n"))))))

    ;; TODO:
    ;;   strip-ansi-escape-sequences

))
