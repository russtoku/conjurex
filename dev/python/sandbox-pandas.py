# sandbox-pandas.py: Sample Python code using Pandas library.

# Set the conda environment before running Neovim to have the python command be
# the one from the conda environment.

# Q: Why does Conjure's Python client treat only the last line of the response
#    for "evaluating" a pandas variable as the return value? The rest is
#    treated as output.
# A: That's the way that the client was written.

import pandas

mydata = {
    'cars': ["BMW", "Volvo", "Ford"],
    'passings': [3, 7, 2]
}

type(mydata)
# => <class 'dict'>

mydata
# => {'cars': ['BMW', 'Volvo', 'Ford'], 'passings': [3, 7, 2]}

str(mydata)
# => "{'cars': ['BMW', 'Volvo', 'Ford'], 'passings': [3, 7, 2]}"

repr(mydata)
# => "{'cars': ['BMW', 'Volvo', 'Ford'], 'passings': [3, 7, 2]}"

df = pandas.DataFrame(mydata)

type(df)
# => <class 'pandas.core.frame.DataFrame'>

df
#     cars  passings
# 0    BMW         3
# 1  Volvo         7
# 2   Ford         2

df[1]
# => KeyError: 1

df['cars']
# 0      BMW
# 1    Volvo
# 2     Ford
# Name: cars, dtype: object

df['passings']
# 0    3
# 1    7
# 2    2
# Name: passings, dtype: int64

for i in range(3):
    print(i)
# 0
# 1
# 2

print("This is printed output.") # This is printed output.

