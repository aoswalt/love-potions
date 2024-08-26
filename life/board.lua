local Board = {}
Board.__index = Board

function Board.new()
  local b = {}
  setmetatable(b, Board)

  b.xCellCount = 100
  b.yCellCount = 75

  b.cells = {}
  b.prevCells = {}

  for y = 1, b.yCellCount do
    b.cells[y] = {}
    b.prevCells[y] = {}
    for x = 1, b.xCellCount do
      b.cells[y][x] = math.random() > 0.5
      b.prevCells[y][x] = false
    end
  end

  -- glider
  -- b.cells[3][4] = true
  -- b.cells[4][5] = true
  -- b.cells[5][3] = true
  -- b.cells[5][4] = true
  -- b.cells[5][5] = true

  return b
end

local function getCell(board, x, y)
  if x < 1 then
    x = board.xCellCount
  end

  if x > board.xCellCount then
    x = 1
  end

  if y < 1 then
    y = board.yCellCount
  end

  if y > board.yCellCount then
    y = 1
  end

  return board.cells[y][x]
end

local function isAlive(board, x, y)
  local neighbors = {
    getCell(board, x - 1, y - 1),
    getCell(board, x - 0, y - 1),
    getCell(board, x + 1, y - 1),

    getCell(board, x - 1, y - 0),
    getCell(board, x + 1, y - 0),

    getCell(board, x - 1, y + 1),
    getCell(board, x - 0, y + 1),
    getCell(board, x + 1, y + 1),
  }

  local numAliveNeighbors = 0

  for _i, cell in pairs(neighbors) do
    if cell then
      numAliveNeighbors = numAliveNeighbors + 1
    end
  end

  if numAliveNeighbors < 2 then
    return false
  elseif numAliveNeighbors == 2 then
    return board.cells[y][x]
  elseif numAliveNeighbors == 3 then
    return true
  elseif numAliveNeighbors > 3 then
    return false
  end
end

function Board:update()
  local nextCells = {}

  nextCells = {}
  for y = 1, self.yCellCount do
    nextCells[y] = {}
    for x = 1, self.xCellCount do
      nextCells[y][x] = isAlive(self, x, y)
    end
  end

  self.prevCells = self.cells
  self.cells = nextCells
end

function Board:draw()
  local tileSize = 10

  for y = 1, self.yCellCount do
    for x = 1, self.xCellCount do
      if self.cells[y][x] then
        love.graphics.setColor(0.65, 0.75, 0.8)
      else
        love.graphics.setColor(0, 0, 0)
      end

      love.graphics.rectangle("fill", (x - 1) * tileSize, (y - 1) * tileSize, tileSize, tileSize)
    end
  end
end

return Board
