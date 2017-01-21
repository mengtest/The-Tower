require("../engine/lclass")

require("../engine/input")
require("../engine/ui/uigroup")
require("../engine/ui/button/button")
require("../engine/screen/screen")
require("../engine/gameobject/gameobject")
require("../engine/gameobject/staticimage")
require("../engine/gameobject/staticobject")
require("../engine/gameobject/ground")
require("../engine/map/map")
require("../engine/map/area")
require("../engine/map/floor")
require("../engine/map/spawnpoint")
require("../engine/collision/collision")
require("../engine/navigation/navmesh")

require("../resources")

require("../game/spider/spider")

class "PlayScreen" ("Screen")

function PlayScreen:PlayScreen(game)
  self.game = game
  self.paused = false
  self.spider = Spider(300, 200)
  self.tree   = nil

  self.camera = game:getCamera()
  self.camera:setTarget( self.game:getPlayer() )
  self.currentMap  = nil

  self:createPauseMenu()
end

function PlayScreen:onEnter()
  self:createTestMap()
end

function PlayScreen:onExit()

end

function PlayScreen:update(dt)

  if ( self.paused ) then
    self:updatePaused(dt)
  else
    self:updateInGame(dt)
  end

end

function PlayScreen:draw()
  self.camera:set()

  self.currentMap:draw()

  self.game:getDrawManager():draw()

  --self.game:getPlayer():draw()

  self.spider:draw()

  self.camera:unset()

  -- menus are not affected by camera
  self.pauseMenu:draw()
end

function PlayScreen:onKeyPress(key, scancode, isrepeat)

end

function PlayScreen:onKeyRelease(key, scancode, isrepeat)

end

function PlayScreen:joystickPressed(joystick, button)

  if ( button == 8 ) then
    self:checkPause()
  end

  if ( self.paused ) then
    self:handleInPauseMenu(joystick, button, self)
  else
    self:handleInGame(joystick, button, self)
  end

end

function PlayScreen:changeMap(newMap, newArea, newFloor, newSpawnPoint)
  self.currentMap = newMap
  self.game:getPlayer():setMap(self.currentMap, newArea, newFloor, newSpawnPoint)
end

function PlayScreen:createPauseMenu()
  self.pauseMenu = UIGroup()

  local continueButton = Button(0, 0, "CONTINUAR", ib_uibutton1, 0.375)
  continueButton:setAnchor(4, 15, 130)

  local exitButton = Button(0, 0, "SAIR", ib_uibutton1, 0.375)
  exitButton:setAnchor(4, 15, 75)
  exitButton.onButtonClick = self.exitButtonClick

  self.pauseMenu:addButton(continueButton)
  self.pauseMenu:addButton(exitButton)

  self.pauseMenu:setVisible(self.paused)
end

function PlayScreen:checkPause()
  if ( self.paused ) then
    self.paused = false
  else
    self.paused = true
    self.pauseMenu:joystickPressed(joystick, button)
    self.pauseMenu:selectFirst()
  end

  self.pauseMenu:setVisible(self.paused)
end

function PlayScreen:handleInPauseMenu(joystick, button)
  self.pauseMenu:joystickPressed(joystick, button, self)
end

function PlayScreen:handleInGame(joystick, button, sender)
  self.game:getPlayer():joystickPressed(joystick, button, self)
end

function PlayScreen:updatePaused(dt)
  self.pauseMenu:update(dt)
end

function PlayScreen:updateInGame(dt)
  self.game:getPlayer():update(dt)

  self.spider:update(dt)

  self.camera:update(dt)

  local coll = collision.check( self.game:getPlayer():getCollider(), self.spider:getCollider() )
end

function PlayScreen:exitButtonClick(sender)
  print("exit the game")
end

function PlayScreen:createTestMap()
  --//TODO remove
  local floor = Floor("TestFloor")

  floor:addGround("grd1", Ground(100, 100, i_deffloor))
  floor:addGround("grd2", Ground(300, 100, i_deffloor))
  floor:addGround("grd3", Ground(500, 100, i_deffloor))
  floor:addGround("grd4", Ground(700, 100, i_deffloor))

  floor:addGround("grd5", Ground(100, 300, i_deffloor))
  floor:addGround("grd6", Ground(300, 300, i_deffloor))
  floor:addGround("grd7", Ground(500, 300, i_deffloor))
  floor:addGround("grd8", Ground(700, 400, i_deffloor))

  local nav = NavMesh()
  nav:addPoint(110, 110)
  nav:addPoint(110, 490)
  nav:addPoint(710, 490)
  nav:addPoint(710, 590)
  nav:addPoint(890, 590)

  nav:addPoint(890, 410)
  nav:addPoint(690, 410)
  nav:addPoint(690, 290)
  nav:addPoint(890, 290)
  nav:addPoint(890, 110)

  floor:setNavMesh(nav)

  self.tree = StaticObject(400, 300, i__tree)
  self.tree:setBoundingBox( BoundingBox(400, 300, 60, 64, 0, 2, 0) )
  self.tree:setCollider( BoxCollider(400, 300, 20, 22, 23, 42) )

  floor:addStaticObject( self.tree )

  local spawnpt = SpawnPoint("Inicio", 400, 200)

  floor:addSpawnPoint( spawnpt:getName(), spawnpt )

  local area = Area("TestArea")

  area:addFloor(floor:getName(), floor)

  local mapa = Map("TestMap")

  mapa:addArea(area:getName(), area)
  mapa:setCurrentAreaByName("TestArea")

  local m = nil

  -- lots of trees:
  --[[
  for i = -50, 50 do
    for j = -50, 50 do
      m = StaticObject( i * 60, j * 60, i__tree)
      m:setBoundingBox( BoundingBox(i * 60, j * 60, 20, 20, 0, 23, 42) )
      area:addStaticObject(m)
      self.game:getDrawManager():addObject(m)
    end
  end
  ]]

  self:changeMap(mapa, area, floor, spawnpt)

  --self.game:getPlayer():setMap(mapa)

  self.game:getDrawManager():addObject(self.game:getPlayer())
  self.game:getDrawManager():addObject(self.tree)
  self.game:getDrawManager():addAllFloors(area:getFloors())
end