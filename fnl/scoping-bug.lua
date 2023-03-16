do
  local a = 42
  local rv_8_, arg1_7_ = nil, nil
  do
    local arg1_7_0 = a
    local _24 = arg1_7_0
    local _241 = arg1_7_0
    rv_8_, arg1_7_ = 1, 2
  end
  a = arg1_7_
  print("should be 2: ", arg1_7_)
end
do
  local a = 2
  local arg1_11_
  do
    local arg1_11_0 = a
    arg1_11_ = 2
  end
  a = arg1_11_
  print("first: ", arg1_11_)
end
local a = 2
local A
do
  local A0 = a
  A = 2
end
a = A
return print("second: ", A)
