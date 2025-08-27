#  Should be able to evaluate all forms in iex REPL.

# Examples taken from Elixir docs.
#   https://hexdocs.pm/elixir/basic-types.html

1                # integer
0x1F             # integer; 31
1.0              # float
true             # boolean
:atom            # atom / symbol
"elixir"         # string
[1, 2, 3]        # list; [1, 2, 3]
{1, 2, 3}        # tuple; {1, 2, 3}

1 + 2            # 3
5 * 5            # 25
10 / 2           # 5.0


div(10, 2)       # 5
div 10, 2        # 5
rem 10, 3        # 1

is_integer(1)    # true
is_integer(2.0)  # false

1 and true    # ** (BadBooleanError) expected a boolean on left-side of "and", got: 1


#   https://hexdocs.pm/elixir/lists-and-tuples.html

[1, 2, true, 3]                                 # [1, 2, true, 3]
length([1, 2, 3])                               # 3

[1, 2, 3] ++ [4, 5, 6]                          # [1, 2, 3, 4, 5, 6]
[1, true, 2, false, 3, true] -- [true, false]   # [1, 2, 3, true]

list = [1, 2, 3]                                # [1, 2, 3]
hd(list)                                        # 1
tl(list)                                        # [2, 3]

hd([])                                          # ** (ArgumentError) argument error
[11, 12, 13]                                    # ~c"\v\f\r"
[104, 101, 108, 108, 111]                       # ~c"hello"

tuple = {:ok, "hello"}                          # {:ok, "hello"}
elem(tuple, 1)                                  # "hello"
tuple_size(tuple)                               # 2

String.split("hello world")                     # ["hello", "world"]
String.split("hello beautiful world")           # ["hello", "beautiful", "world"]

String.split_at("hello world", 3)               # {"hel", "lo world"}
String.split_at("hello world", -4)              # {"hello w", "orld"}


#   https://hexdocs.pm/elixir/case-cond-and-if.html

case {1, 2, 3} do
  {4, 5, 6} ->
    "This clause won't match"
  {1, x, 3} ->
    "This clause will match and bind x to 2 in this clause"
  _ ->
    "This clause would match any value"
end                                             # "This clause will match and bind x to 2 in this clause"

case {1, 2, 3} do
  {1, x, 3} when x > 0 ->
    "Will match"
  _ ->
    "Would match, if guard condition were not satisfied"
end                                             # "Will match"

x = 1                                           # 1
x = if true do
  x + 1
else
  x
end                                             # 2

cond do
  2 + 2 == 5 ->
    "This is never true"
  2 * 2 == 3 ->
    "Nor this"
  true -> 
    "This is always true (equivalent to else)"
end                                             # "This is always true (equivalent to else)"


