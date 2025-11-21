-- https://stackoverflow.com/a/27028488
function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

-- foo = {}
-- setmetatable(foo, { __shl = function (t,v) t[#t+1]=v end })
-- _= foo << "bar"
-- _= foo << "baz"
