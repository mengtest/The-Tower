

require("..engine.lclass")
require("..engine.io.io")

require("..editor.textinput")

local allanimations = {}

local modfun = math.fmod
local floorfun = math.floor

local options = {
  "F1 - New Animation",
  "F2 - Edit Name",
  "F3 - Remove Animation",
  "F4 - Edit Animation",
  "",
  "F6 - Auto Animator",
  "",
  "F9 - Save",
  "F11 - Back",
  "",
  "Pg Up - Previous Page",
  "Pg Down - Next Page"
}

class "AnimationList"

function AnimationList:AnimationList( ownerEditor, thegame )
  self.game      = thegame
  self.editor    = ownerEditor

  self.pageIndex = 1
  self.selIndex  = 1
  self.listStart = 1
  self.listEnd   = 1

  self.mode      = 0
  self.inputMode = 0
  self.textInput = nil

  self.renamed = {}

  self.animationEditor = nil

  self.tempData  = nil

  self.autonames = {}
end

function AnimationList:save()
  for i=1, #self.renamed do
    self.game:getAnimationManager():renameAnimation( self.renamed[i].old, self.renamed[i].new )
  end

  self.game:getAnimationManager():save( allanimations )

  self.renamed = {}
end

function AnimationList:load()
  allanimations = self.game:getAnimationManager():load()

  if ( not allanimations ) then
    allanimations = {}
  end

end

function AnimationList:onEnter()
  print( "Entered AnimationList" )

  self:load()
  self:refreshList()
end

function AnimationList:onExit()

end

function AnimationList:update( dt )
  if ( self.mode == 1 or self.mode == 2 ) then
    self:updateAddEdit( dt )
    return
  end

  if ( self.mode == 5 ) then
    self:updateAutoAnimation( dt )
    return
  end

  if ( self.animationEditor ) then
    self.animationEditor:update( dt )
    return
  end

end

function AnimationList:draw()
  if ( self.textInput ) then

    self.textInput:draw()

  elseif ( self.animationEditor ) then
      self.animationEditor:draw()
  else
    for i = 1, #options do
      love.graphics.print( options[i], 16, ( i * 16 ) + 40 )
    end

    self:drawAnimationList()
  end

end

function AnimationList:drawAnimationList()

  love.graphics.setColor( 0, 255, 100, 255 )
  love.graphics.print( "Name", 200, 56 )
  love.graphics.setColor( colors.WHITE )

  if ( #allanimations == 0 ) then
    return
  end

  love.graphics.setColor( 255, 255, 255, 80 )
  love.graphics.rectangle( "fill", 190, ( self.selIndex * 16 ) + 56, 1000, 18 )
  love.graphics.setColor( colors.WHITE )

  for i = self.listStart, self.listEnd do
    love.graphics.print( allanimations[i][1], 200, ( ( i - self.listStart + 1 ) * 16 ) + 56 )
  end

end

function AnimationList:addToList( name, mode )
  mode = mode or 1

  self.tempData[1] = name

  if ( mode == 1 ) then
    table.insert( allanimations, self.tempData )
  else
    table.insert( self.renamed, { old = allanimations[self.selIndex][1], new = self.tempData[1] } )
    allanimations[self.selIndex] = self.tempData
  end

end

function AnimationList:updateAddEdit( dt )
  if ( self.textInput:isFinished() ) then
    self.inputMode = self.inputMode + 1

    if ( self.inputMode == 2 ) then -- have everything
      self:addToList( self.textInput:getText(), self.mode )

      self.tempData  = nil
      self.inputMode = 0
      self.mode      = 0
      self.textInput = nil

      self:refreshList()
    end

  end
end

function AnimationList:setAutoNames( autonameslist )
  self.autonames = autonameslist
end


function AnimationList:onKeyPress( key, scancode, isrepeat )
  if ( self.mode == 1 or self.mode == 2 ) then
    self.textInput:keypressed( key )
    return
  end

  if ( self.animationEditor  ) then
    self.animationEditor:onKeyPress( key, scancode, isrepeat )
    return
  end

  if ( key == "f1" ) then
    self:addMode()
  end

  if ( key == "f2" ) then
    self:editMode()
  end

  if ( key == "f3" ) then
    self:removeSelected()
  end

  if ( key == "f4" ) then
    self:editSelected()
  end

  if ( key == "f6" ) then
    self:openAutoAnimator()
  end

  if ( key == "pageup" ) then
    self:listUp()
  end

  if ( key == "pagedown" ) then
    self:listDown()
  end

  if ( key == "up" ) then
    if ( Input:isKeyDown("lctrl") ) then
      self:selectPrevious(10)
    else
      self:selectPrevious()
    end
  end

  if ( key == "down" ) then
    if ( Input:isKeyDown("lctrl") ) then
      self:selectNext(10)
    else
      self:selectNext()
    end
  end

  if ( key == "f9" ) then
    self:save()
    return
  end

  if ( key == "f11" ) then
    self.editor:backFromEdit()
    return
  end
end

function AnimationList:onMousePress( x, y, button, istouch )
  if ( self.animationEditor ) then

    if ( self.animationEditor.onMousePress ) then
      self.animationEditor:onMousePress( x, y, button, istouch )
    end

  end
end

function AnimationList:onMouseRelease( x, y, button, istouch )
  if ( self.animationEditor ) then

    if ( self.animationEditor.onMouseRelease ) then
      self.animationEditor:onMouseRelease( x, y, button, istouch )
    end

  end
end

function AnimationList:onMouseMove( x, y, dx, dy )

  if ( self.animationEditor ) then

    if ( self.animationEditor.onMouseMove ) then
      self.animationEditor:onMouseMove( x, y, dx, dy )
    end

  end
end

function AnimationList:removeSelected()
  local delIndex = self.selIndex + ( self.pageIndex - 1 ) * 40

  table.remove( allanimations, delIndex )

  self:refreshList()
end

function AnimationList:doTextInput ( t )
  if ( self.textInput ) then
    self.textInput:input( t )
    return
  end

  if ( self.animationEditor ) then
    self.animationEditor:doTextInput( t )
    return
  end

end

function AnimationList:addMode()
  self.tempData  = {}
  self.mode      = 1
  self.inputMode = 1
  self.textInput = TextInput( "Animation Name:" )
end

function AnimationList:editMode()
  self.tempData  = {}
  self.mode      = 2
  self.inputMode = 1
  self.textInput = TextInput( "Animation Name:", allanimations[self.selIndex][1] )
end

function AnimationList:editSelected()
  local animationindex = self.selIndex + ( self.pageIndex - 1 ) * 40

  self.mode = 4

  self.animationEditor = AnimationEditor( self, animationindex, allanimations[animationindex][1], self.game )

  self.animationEditor:onEnter()
end

function AnimationList:openAutoAnimator()
  self.mode = 8

  self.animationEditor = AutoAnimator( self, self.game )

  self.animationEditor:onEnter()
end

function AnimationList:backFromEdit()
  self.animationEditor = nil
end

function AnimationList:refreshList()
  --//TODO go to same page ?
  self.selIndex  = 1
  self.pageIndex = 1

  self.listStart = ( self.pageIndex - 1 ) * 40 + 1

  self.listEnd = self.listStart + 40 - 1

  if ( self.listEnd > #allanimations ) then
    self.listEnd   = #allanimations
  end
end

function AnimationList:selectPrevious( steps )
  steps = steps or 1

  self.selIndex = self.selIndex - steps

  if ( self.selIndex <= 0 ) then
    self.selIndex = 1
  end
end

function AnimationList:selectNext( steps )
  steps = steps or 1

  self.selIndex = self.selIndex + steps

  --//TODO get list bounds
  if ( self.selIndex > 40 ) then
    self.selIndex = 40
  end

  if ( self.listEnd < self.selIndex ) then
     self.selIndex = self.listEnd
  end
end

function AnimationList:listUp()
  self.pageIndex = self.pageIndex - 1

  if ( self.pageIndex == 0 ) then
    self.pageIndex = 1
  end

  self.listStart = (self.pageIndex - 1) * 40 + 1

  self.listEnd = self.listStart + 40 - 1

  if ( self.listEnd > #allanimations ) then
    self.listEnd = #allanimations
  end
end

function AnimationList:listDown()
  self.pageIndex = self.pageIndex + 1

  if ( self.pageIndex > modfun( #allanimations, 40 ) ) then
    self.pageIndex = modfun( #allanimations, 40 )
  end

  self.listStart = ( self.pageIndex - 1 ) * 40 + 1

  self.listEnd = self.listStart + 40

  if ( self.listEnd > #allanimations ) then
    self.listEnd = #allanimations
  end

end
