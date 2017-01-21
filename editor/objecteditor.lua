require("../engine/lclass")
require("../engine/input")
require("../engine/io/io")
require("../engine/resourcemanager")

require("../editor/textinput")

local absfun = math.abs

class "ObjectEditor"

local generalOptions = {
  "Numpad '+/-' - Change Inc Modifier",
  "F8 - Toogle View All/View Quad",
  "F9 - Save",
  "F11 - Back"
}

local mainOptions = {
  "F1 - Select Resource",
  "F2 - Edit Quad",
  "",
  "F4 - Edit Bounding Box",
  "F5 - Edit Collider"
}

local quadOptions = {
  "Numpad 5 - Use all image",
  "Numpad 2,4,6,8 - Increase on direction",
  "Numpad+Ctrl - Decrease on direction",
  "Up,Down,Left, Right - Move"
}

local boundingboxOptions = {
  "Numpad 5 - Use all image",
  "Numpad 2,4,6,8 - Increase on direction",
  "Numpad+Ctrl - Decrease on direction"
}

local colliderOptions = {
  "Numpad 5 - Use all image",
  "Numpad 2,4,6,8 - Increase on direction",
  "Numpad+Ctrl - Decrease on direction",
  "C - Change collider type"
}

local options = mainOptions

function ObjectEditor:ObjectEditor( objectListOwner, objectIndex, objectName, objectData )
  self.objectList = objectListOwner

  self.index = objectIndex
  self.name  = objectName
  self.data  = objectData

  self.showQuad = true

  self.mode = 0

  self.incModifier = 1

  self.resourceManager = ResourceManager()

  self.object = nil

  self.textInput = nil

  self.updatefunction = self.updateNone
  self.keypressfunction = self.keypressNone
end

function ObjectEditor:onEnter()
  print("Entered ObjectEditor")
end

function ObjectEditor:onExit()
  self.resmanager = nil
end

function ObjectEditor:draw()
  if ( self.mode == 1 ) then
    self.textInput:draw()
    return
  end

  for i = 1, #options do
    love.graphics.print(options[i], 16, (i * 16) + 40)
  end

  for i = 1, #generalOptions do
    love.graphics.print(generalOptions[i], 16, (i * 16) + 350)
  end

  love.graphics.line(299, 0, 299, 2000)
  love.graphics.line(299, 99, 2000, 99)

  love.graphics.print("Inc Modifier: " .. self.incModifier, 16, 300)

  self:printObject()
end

function ObjectEditor:printObject()
  if ( self.object == nil ) then
    return
  end

  if ( self.showQuad == true ) then
    if ( self.object.quad ~= nil ) then
      love.graphics.draw(self.object.image, self.object.quad, 300, 100, 0, self.object.scale, self.object.scale)

      local x, y = self.object.quaddata[1], self.object.quaddata[2]
      local w, h = self.object.quaddata[3], self.object.quaddata[4]

      love.graphics.setColor(255, 100, 100, 200)
      love.graphics.rectangle("line", x + 300, y + 100, w, h)
      love.graphics.setColor(glob.defaultColor)
    else
      love.graphics.draw(self.object.image, 300, 100, 0, self.object.scale, self.object.scale)
    end

  else
    love.graphics.draw(self.object.image, 300, 100, 0, self.object.scale, self.object.scale)
  end

  if  ( self.object.boundingbox ~= nil ) then
    self.object.boundingbox:draw()
  end

  if  ( self.object.collider ~= nil ) then
    self.object.collider:draw()
  end

end

function ObjectEditor:update(dt)

  self:updatefunction( dt )

end

function ObjectEditor:updateNone(dt)

end

function ObjectEditor:updateGetResource(dt)
  if ( self.textInput:isFinished() ) then

    local resname, restype, respath = self.resourceManager:getResourceByName(self.textInput:getText())

    if ( restype == "image" ) then
      self.object = {}
      self.object.resourceName = resname
      self.object.resourceType = restype
      self.object.resourcePath = respath

      self.object.image       = self.resourceManager:loadImage(respath)
      self.object.scale       = 1
      self.object.quad        = nil
      self.object.boundingbox = nil
      self.object.collider    = nil

      local w, h = self.object.image:getWidth(), self.object.image:getHeight()

      self.object.quaddata = { 0, 0, w, h, w, h }

      self.object.bboxdata = { 0, 0, w, h, 0, 0, 0, 1 }
    end

    self.textInput = nil

    self.mode = 0

    self.updatefunction   = self.updateNone
    self.keypressfunction = self.keypressNone
  end
end

function ObjectEditor:updateEditQuad(dt)
end

function ObjectEditor:updateEditBoundinBox(dt)
end

function ObjectEditor:updateEditCollider(dt)
end

function ObjectEditor:doTextInput ( t )

  if ( self.textInput ~= nil ) then
    self.textInput:input( t )
  end

end

function ObjectEditor:onKeyPress( key, scancode, isrepeat )

  if ( key == "kp+" ) then

    if ( self.incModifier == 1 ) then
      self.incModifier = 5
    else
      self.incModifier = self.incModifier + 5

      if ( self.incModifier > 50 ) then
        self.incModifier = 50
      end
    end

    print(" IncModifier : " .. self.incModifier)

  end

  if ( key == "kp-" ) then

    if ( self.incModifier <= 5 ) then
      self.incModifier = 1
    else
      self.incModifier = self.incModifier - 5
    end

    print(" IncModifier : " .. self.incModifier)

  end

  if ( key == "f8" ) then
    self.showQuad = not self.showQuad

    return
  end

  if ( key == "f9" ) then
    self:saveObject()

    return
  end

  if ( key == "f11" ) then

    if (self.mode ~= 0) then
      self.mode = 0

      options = mainOptions

      self.updatefunction   = self.updateNone
      self.keypressfunction = self.keypressNone

      return
    end

  end

  self:keypressfunction( key )

end

function ObjectEditor:keypressNone( key )

  if ( self.mode == 1 ) then
    self.textInput:keypressed( key )
    return
  end

  if ( key == "f1" ) then
    self.mode = 1

    self.textInput = TextInput("Resource Name: ")

    self.updatefunction = self.updateGetResource

    return
  end

  if ( key == "f2" ) then
    self.mode = 2

    options = quadOptions

    local d = self.object.quaddata

    self.object.quad = love.graphics.newQuad( d[1], d[2], d[3], d[4], d[5], d[6] )

    self.updatefunction   = self.updateEditQuad
    self.keypressfunction = self.keypressEditQuad

    return
  end

  if ( key == "f4" ) then
    self.mode = 4

    options = boundingboxOptions

    local bb = self.object.bboxdata

    if ( self.object.quad ~= nil ) then
      self.object.boundingbox = BoundingBox(bb[1] + 300, bb[2] + 100, self.object.quaddata[3], self.object.quaddata[4], bb[5], bb[6], bb[7], bb[8])
    else
      self.object.boundingbox = BoundingBox(bb[1] + 300, bb[2] + 100, bb[3], bb[4], bb[5], bb[6], bb[7], bb[8])
    end

    self.updatefunction   = self.updateEditBoundinBox
    self.keypressfunction = self.keypressEditBoundinBox

    return
  end

  if ( key == "f5" ) then
    self.mode = 5

    options = colliderOptions

    self.updatefunction   = self.updateEditCollider
    self.keypressfunction = self.keypressEditCollider

    return
  end

  if ( key == "f11") then
    self.objectList:backFromEdit()
    return
  end

end

function ObjectEditor:keypressEditQuad ( key )
  if ( key == "kp5" ) then
    local w, h = self.object.image:getWidth(), self.object.image:getHeight()

    self.object.quaddata = { 0, 0, w, h, w, h }

    self.object.quad = love.graphics.newQuad( 0, 0, w, h, w, h )
  end

  local inc = 1

  if ( Input:isKeyDown("lctrl") ) then
    inc = -1
  end

  inc = inc * self.incModifier

  if  ( key == "kp2" ) then -- h
    self.object.quaddata[4] = self.object.quaddata[4] + inc
  end

  if  ( key == "kp4" ) then -- x, w
    self.object.quaddata[1] = self.object.quaddata[1] - inc
    self.object.quaddata[3] = self.object.quaddata[3] + inc
  end

  if  ( key == "kp6" ) then -- w
    self.object.quaddata[3] = self.object.quaddata[3] + inc
  end

  if  ( key == "kp8" ) then -- y, h
    self.object.quaddata[2] = self.object.quaddata[2] - inc
    self.object.quaddata[4] = self.object.quaddata[4] + inc
  end

  if  ( key == "left" ) then -- x
    inc = absfun(inc)

    self.object.quaddata[1] = self.object.quaddata[1] - inc
  end

  if  ( key == "right" ) then -- x
    inc = absfun(inc)

    self.object.quaddata[1] = self.object.quaddata[1] + inc
  end

  if  ( key == "up" ) then -- x
    inc = absfun(inc)

    self.object.quaddata[2] = self.object.quaddata[2] - inc
  end

  if  ( key == "down" ) then -- x
    inc = absfun(inc)

    self.object.quaddata[2] = self.object.quaddata[2] + inc
  end

  local d = self.object.quaddata

  self.object.quad = love.graphics.newQuad( d[1], d[2], d[3], d[4], d[5], d[6] )
end

function ObjectEditor:keypressEditBoundinBox ( key )

  -- "Numpad 2,4,6,8 - Increase on direction",
  -- "Numpad+Ctrl - Decrease on direction"

  if ( key == "kp5" ) then
    local w, h = self.object.image:getWidth(), self.object.image:getHeight()

    if ( self.object.quad ~= nil ) then
      self.object.bboxdata = {0, 0, self.object.quaddata[3], self.object.quaddata[4], 0, 0, 0, 1}
    else
      self.object.bboxdata = {0, 0, w, h, 0, 0, 0, 1}
    end

  end

  local inc = 1

  if ( Input:isKeyDown("lctrl") ) then
    inc = -1
  end

  inc = inc * self.incModifier

  if  ( key == "kp2" ) then -- h
    self.object.bboxdata[4] = self.object.bboxdata[1] + inc
  end

  if  ( key == "kp4" ) then -- off x, w
    self.object.bboxdata[6] = self.object.bboxdata[6] - inc
    self.object.bboxdata[3] = self.object.bboxdata[3] + inc
  end

  if  ( key == "kp6" ) then -- w
    self.object.bboxdata[3] = self.object.bboxdata[3] + inc
  end

  if  ( key == "kp8" ) then -- off y, h
    self.object.bboxdata[7] = self.object.bboxdata[7] - inc
    self.object.bboxdata[4] = self.object.bboxdata[4] + inc
  end

  if  ( key == "left" ) then -- off x
    inc = absfun(inc)

    self.object.bboxdata[6] = self.object.bboxdata[6] - inc
  end

  if  ( key == "right" ) then -- off x
    inc = absfun(inc)

    self.object.bboxdata[6] = self.object.bboxdata[6] + inc
  end

  if  ( key == "up" ) then -- off y
    inc = absfun(inc)

    self.object.bboxdata[7] = self.object.bboxdata[7] - inc
  end

  if  ( key == "down" ) then -- off y
    inc = absfun(inc)

    self.object.bboxdata[7] = self.object.bboxdata[7] + inc
  end

  local bb = self.object.bboxdata

  self.object.boundingbox = BoundingBox(bb[1] + 300, bb[2] + 100, bb[3], bb[4], bb[5], bb[6], bb[7], bb[8])
  --self.object.boundingbox = BoundingBox(b[1] + 300, b[2] + 100, b[3], b[4], b[5], b[6], b[7], b[8])
end

function ObjectEditor:keypressEditCollider ( key )

end

function ObjectEditor:saveObject()
  print("save to a file")
end