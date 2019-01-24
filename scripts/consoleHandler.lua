require "/scripts/messageutil.lua"

local oldInit = init

init = function()
  if oldInit then oldInit() end
  
  message.setHandler("can_call", localHandler(can_call))
  message.setHandler("call_fn", localHandler(call_fn))
end


function can_call(module, func) 
   if module and func then return not not (_ENV[module] and _ENV[module][func])
   elseif module then return not not _ENV[module] 
   end 
   return false
end

function call_fn(module, func, ...)
   if can_call(module, func) and func then 
      return _ENV[module][func](...)
   end
end