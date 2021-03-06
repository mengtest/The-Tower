require("..engine.lclass")

require("..game.scripts.testmap.openenddoor")

local gameobject = nil

local used = false

scriptsetup = function( object )
  gameobject = object

  gameobject.onCollisionEnter = usegreenkeyCollisionEnter
end

usegreenkeyCollisionEnter = function ( caller, otherCollider )

  if ( used ) then
    return
  end

  if ( otherCollider:getOwner():getInstanceName() ~= "PLAYER" ) then
    return
  end

  if ( getGame():getInventory():consumeItem( "greenkey" ) ) then
    getGame():getMessageBox():show( "Usou a Chave Verde" )
    getGame():getSaveGame():addEventKey( "greenkeyopen", 1 )
    openEndDoor()
    used = true
  else
    getGame():getMessageBox():show( "Falta a Chave Verde" )
  end
end
