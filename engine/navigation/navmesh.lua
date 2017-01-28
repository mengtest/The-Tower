-- http://gamedev.stackexchange.com/questions/7735/how-do-i-test-if-a-circle-and-concave-polygon-intersect
-- https://love2d.org/wiki/General_math
-- http://grepcode.com/file/repository.grepcode.com/java/root/jdk/openjdk/7-b147/java/awt/geom/Line2D.java#Line2D.linesIntersect(double,double,double,double,double,double,double,double)

--[[

a navmesh is the walkable part of an floor

]]

require("../engine/lclass")

require("../engine/globalconf")

local Vec = require("../engine/math/vector")

class "NavMesh"

function NavMesh:NavMesh()
  self.owner = nil

  self.coords     = {} --pairs of points of the mesh (polygon)
  self.lines      = {} -- precomputed for speed
  self.lineCount  = 0

  self.mobile = false

  self.simpleColliders      = {}
  self.simpleCollidersCount = 0
end

function NavMesh:draw()
  if ( glob.devMode.drawNavMesh ) then
    love.graphics.setColor(0, 255, 255)

    love.graphics.polygon( "line", self.coords )

    love.graphics.setColor( glob.defaultColor )
  end
end

function NavMesh:setOwner( newOwner )
  self.owner = newOwner
end

function NavMesh:getOwner()
  return self.owner
end

function NavMesh:addPoint(pointX, pointY)

  table.insert(self.coords, pointX)
  table.insert(self.coords, pointY)

  self:recomputeLines()
end

function NavMesh:recomputeLines()
  --//TODO refactor make a better name and check for a better calling moment

  -- each time a point is created this is called

  -- create a line between the points
  if ( #self.coords >= 4 ) then

    self.lines = {}

    self.lineCount = 0

    for i = 1, #self.coords - 2, 2 do

      local line = {
        self.coords[i],
        self.coords[i + 1],
        self.coords[i + 2],
        self.coords[i + 3]
      }

      table.insert(self.lines, line)

      self.lineCount = self.lineCount + 1

    end

    line = {
      self.coords[#self.coords - 1],
      self.coords[#self.coords],
      self.coords[1],
      self.coords[2]
    }

    table.insert(self.lines, line)

    self.lineCount = #self.lines

  end

end

function NavMesh:changePosition( movementVector )

  for i=1, #self.coords, 2 do
    self.coords[i]   = self.coords[i] + movementVector.x
    self.coords[i+1] = self.coords[i+1] + movementVector.y
  end

  for i=1, #self.lines do
    self.lines[i][1] = self.lines[i][1] + movementVector.x
    self.lines[i][2] = self.lines[i][2] + movementVector.y
    self.lines[i][3] = self.lines[i][3] + movementVector.x
    self.lines[i][4] = self.lines[i][4] + movementVector.y
  end

end

function NavMesh:addSimpleCollider( colliderToAdd )
  table.insert( self.simpleColliders, colliderToAdd )
  self.simpleCollidersCount = #self.simpleColliders
end

function NavMesh:setMobile( isMobile )
  self.mobile = isMobile
end

function NavMesh:isMobile()
  return self.mobile
end

function NavMesh:getCollisionCheckedPosition ( currentPosition, movementVector, objectCollider )
  local movedPosition = Vec( currentPosition.x + movementVector.x,  currentPosition.y + movementVector.y)

  local futureCollider = objectCollider:clone()

  futureCollider:changePosition( movementVector.x , movementVector.y )

  local collided = false

  local collIndex = 1

  local checkedAll = self.simpleCollidersCount == 0 -- if no colliders, no check

  while not checkedAll do
    collided = collision.check( futureCollider, self.simpleColliders[collIndex])

    if ( collided ) then
      movementVector:set(0,0) --//TODO change to check the collision and keep moving?

      --[[ --FIX code below is not working properly, so we set vector to 0 for now
      movementVector = self:orientedCollisionCheck( objectCollider, self.staticColliders[collIndex], movementVector )

      if ( movementVector.x == 0 and movementVector.y == 0 ) then
        checkedAll = true -- cant move, so exit loop
      end
    else
      collIndex = collIndex + 1
      checkedAll = collIndex >= self.staticCollidersCount
    end

    ]]

    end

    collIndex = collIndex + 1

    checkedAll = collIndex > self.simpleCollidersCount
  end

  return movementVector
end

function NavMesh:orientedCollisionCheck( coll1, coll2, movementVector )
  -- checks whether a collided object can keep moving on in one direction
  -- at least, if the movement is diagonal (x not equal 0, y not equal 0)

  local collx = coll1:clone()
  local colly = coll1:clone()

  collx:changePosition(movementVector.x, 0)
  colly:changePosition(0, movementVector.y)

  local collidedX = collision.check( collx, coll2 )
  local collidedY = collision.check( colly, coll2 )

  if (collidedX and collidedY) then

    return Vec(0,0) -- collided both, cant move

  elseif (collidedX) then

    return Vec(0,movementVector.y) -- can keep going on Y

  else

    return Vec(movementVector.x, 0) -- can keep going on X

  end

end

function NavMesh:getInsidePosition( currentPosition, movementVector )

  local newX = currentPosition.x + movementVector.x
  local newY = currentPosition.y + movementVector.y

  if self:isInside( newX, newY ) then
    return movementVector
  else

    if ( self:isInside( currentPosition.x, newY ) ) then -- no change in X

      return Vec(0, movementVector.y )

    elseif ( self:isInside( newX, currentPosition.y ) ) then -- no change in Y

      return Vec( movementVector.x, 0 )

    else -- cant go where it wants

      return Vec( 0, 0 )

    end

  end

end

function NavMesh:isInside( centerX, centerY )
  -- far ended horizontal line to the right
  --//TODO check if 1000000000 is enough :D
  local intersections = self:countIntersections(centerX, centerY, 1000000000, centerY)

  return (intersections % 2) == 1
end

function NavMesh:countIntersections(centerX, centerY, endx, endy)
  local total = 0

  -- data from other line

  for i = 1, self.lineCount do
    local lx1, ly1, lx2, ly2 =
      self.lines[i][1], self.lines[i][2], self.lines[i][3], self.lines[i][4]

    if ( linesIntersect (centerX, centerY, endx, endy, lx1, ly1, lx2, ly2) ) then
      total = total + 1
    end

  end

  return total
end

function linesIntersect( x1, y1, x2, y2, x3, y3, x4, y4 )

  return (
    (relativeCCW(x1, y1, x2, y2, x3, y3) * relativeCCW(x1, y1, x2, y2, x4, y4) <= 0) and
    (relativeCCW(x3, y3, x4, y4, x1, y1) * relativeCCW(x3, y3, x4, y4, x2, y2) <= 0)
  )

end

function relativeCCW( x1, y1, x2, y2, px, py )

  x2 = x2 - x1;
  y2 = y2 - y1;
  px = px - x1;
  py = py - y1;

  local ccw = px * y2 - py * x2;

  if (ccw == 0.0) then
    --[[
    The point is colinear, classify based on which side of
    the segment the point falls on.  We can calculate a
    relative value using the projection of px,py onto the
    segment - a negative value indicates the point projects
    outside of the segment in the direction of the particular
    endpoint used as the origin for the projection.
    ]]--

    ccw = px * x2 + py * y2;

    if (ccw > 0.0) then
      --[[
      Reverse the projection to be relative to the original x2,y2
      x2 and y2 are simply negated.
      px and py need to have (x2 - x1) or (y2 - y1) subtracted
      from them (based on the original values)
      Since we really want to get a positive answer when the
      point is "beyond (x2,y2)", then we want to calculate
      the inverse anyway - thus we leave x2 & y2 negated.
      ]]--

      px = px - x2;
      py = py - y2;
      ccw = px * x2 + py * y2;

      if (ccw < 0.0) then
        ccw = 0.0;
      end

    end

  end

  if (ccw < 0.0) then
    return -1
  elseif (ccw > 0.0) then
    return 1
  else
    return 0
  end

end
