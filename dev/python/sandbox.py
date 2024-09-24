import csv
import datetime

datetime.datetime.now() # datetime.datetime(2024, 9, 22, 11, 22, 47, 121454)

def add(a, b):
    return a + b

add(4, 29) # 33

4 + 9 # 13

5 + \
7 + \
9 # 21

"hello" # 'hello'

print("hello world") # hello world

a = "foo"
print(a) # foo

a, b = [1, 2]

def print_things_then_return():
    """
    Print things then return!
    """
    for i in range(4):
        print(i)
    return "all done!"

print_things_then_return()
# 0
# 1
# 2
# 3
# 'all done!'

def newline_in_function_bug():
    return "hey" + "\n" + "\tho"

newline_in_function_bug() # 'hey\n\tho'

print(newline_in_function_bug())
# hey
# 	ho

def fn4():
    return 'a\nb\\ncde'

print(fn4())
# a
# b\ncde


"\n".join(['a','b', "cde"]) # 'a\nb\ncde'
# To evaluate the list, use selection and '<localleader>E'.
# With cursor on opening bracket, can also use '<localleader>E%'.


print("\n".join(['a','b', "cde"]))
# a
# b
# cde


def fn3():
    print("\n".join(['a','b', "cde"]))

fn3()
# a
# b
# cde

def fn2():
    a = 42
    return f"The answer is a.\nOf course, a is {a}"

print(fn2())
# The answer is a.
# Of course, a is 42


for i in range(20):
    print(i)
# 0
# 1
# 2
# 3
# 4
# 5
# 6
# 7
# 8
# 9
# 10
# 11
# 12
# 13
# 14
# 15
# 16
# 17
# 18
# 19

def fn_with_multiline_str():
    description = """
    This is a super long,
    descriptive, multiline string.
    """
    print(f'Description: {description}')

fn_with_multiline_str()
# Description: 
#     This is a super long,
#     descriptive, multiline string.
#     

def fn5():
    description = """
    This is a super long,
    descriptive, multiline string.
"""
    print(f'Description: {description}')

fn5()
# Description: 
#     This is a super long,
#     descriptive, multiline string.

