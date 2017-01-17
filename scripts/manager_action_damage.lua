-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


DICE_DEFAULT = 6;

function onInit()
	ActionsManager.registerResultHandler("damage", onDamage);
end

function onDamage(rSource, rTarget, rRoll)
  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  local nTotal = 0;

  local bAddMod = false;
  if GameSystem.actions[rRoll.sType] then
    bAddMod = GameSystem.actions[rRoll.sType].bAddMod;
  end

  -- Send the chat message
  local bShowMsg = true;
  if not rSource then
    bShowMsg = false;
  end
  
  if bShowMsg then
    local _, _, sOperator, nNum = parseDamage(rRoll.sDamage);
    
    rMessage.text = string.format("%s\n%s%s%s %s",
        (string.format("%s%s",(rTarget and string.format("%s || ",rTarget.sName) or ""), rMessage.text)),
        (rRoll.sWeapon or ""), 
        ((rRoll.sWeapon and rRoll.sWeapon ~= '' and rRoll.sMode and rRoll.sMode ~= '') and "\n" or ""), 
        (rRoll.sMode or ""), 
        (string.format("[%s]%s", (rRoll.sDamage or ""), (rRoll.nMod ~= 0 and string.format("(%s%d)",(rRoll.nMod > 0 and "+" or ""),rRoll.nMod) or "")) or "")
    );

    rMessage.diemodifier = 0;
    
    -- Calculate Damage 
    for _,v in ipairs(rRoll.aDice) do
      nTotal = nTotal + v.result;
    end
  
    local nMod = (bAddMod and rRoll.nMod or 0);
    if sOperator then 
      if (sOperator == "+") then
        nTotal = nTotal + (nNum or 0);
        rMessage.diemodifier = (nNum or 0) + nMod;
      elseif (sOperator == "-") then
        nTotal = nTotal - (nNum or 0);
        rMessage.diemodifier = -(nNum or 0) + nMod;
      elseif (sOperator == "x") then
        nTotal = nTotal * (nNum or 1);
        rMessage.diemodifier = 0;
      end
    end
    nTotal = nTotal + nMod;
    Comm.deliverChatMessage(rMessage);

    -- Deliver Total Damage
    rMessage.type = "number";
    rMessage.icon = "action_damage";
    rMessage.text = string.format("Total [%s]%s", (rRoll.sDamage or ""), (rRoll.nMod ~= 0 and string.format("(%s%d)",(rRoll.nMod > 0 and "+" or ""),rRoll.nMod) or ""));
    rMessage.dice = {};
    rMessage.diemodifier = (nTotal > 0 and nTotal or 0);
    rMessage.dicedisplay = 0;
    Comm.deliverChatMessage(rMessage);
  end
end

function applyDamage(rSource, rTarget, bSecret, sDamage, nTotal)
  -- Get health fields
  local sTargetType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
  if sTargetType ~= "pc" and sTargetType ~= "ct" then
    return;
  end

  local nHP, nCHP;
  if sTargetType == "pc" then
    nHP = DB.getValue(nodeTarget, "attributes.hitpoints", 0);
    nCHP = DB.getValue(nodeTarget, "attributes.hps", 0) - nTotal;
    DB.setValue(nodeTarget, "attributes.hps", "number", nCHP);
  else
    nHP = DB.getValue(nodeTarget, "attributes.hitpoints", 0);
    nCHP = DB.getValue(nodeTarget, "hps", 0) - nTotal;
    DB.setValue(nodeTarget, "hps", "number", nCHP);
  end
end

function parseDamage(s)
  -- SETUP
  local aDice = {};
  local nMod = 0;
  
  local nDieCount = 0;
  local nDice = 0;
  local sOperator = "";
  local nNum = 0
  
  -- PARSING
  if s then
    nDieCount, nDice, sOperator, nNum = s:match("^(%d*)[dD]([%dF]*)%s*([+-x]?)%s*([%dF]*)");
    
    if nDieCount then
      local sDie = string.format("d%d", (tonumber(nDice) or DICE_DEFAULT));
      
      for i = 1, nDieCount do
        table.insert(aDice, sDie);
      end
    end
    
    if sOperator and nNum then
      nNum = (tonumber(nNum) or 0);
    end
  end
  
  -- RESULTS
  return aDice, nMod, sOperator, nNum;
end

