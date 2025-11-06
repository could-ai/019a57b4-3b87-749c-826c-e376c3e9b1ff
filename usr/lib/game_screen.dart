import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int gridSize = 4;
  List<List<int>> grid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
  int score = 0;
  int bestScore = 0;
  bool gameOver = false;
  final Random random = Random();
  
  late AnimationController _mergeController;
  late AnimationController _moveController;
  Set<String> mergedTiles = {};

  @override
  void initState() {
    super.initState();
    _mergeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _initGame();
  }

  @override
  void dispose() {
    _mergeController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  void _initGame() {
    grid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    score = 0;
    gameOver = false;
    mergedTiles.clear();
    _addRandomTile();
    _addRandomTile();
    setState(() {});
  }

  void _addRandomTile() {
    List<Point<int>> emptyCells = [];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == 0) {
          emptyCells.add(Point(i, j));
        }
      }
    }
    if (emptyCells.isNotEmpty) {
      Point<int> cell = emptyCells[random.nextInt(emptyCells.length)];
      grid[cell.x][cell.y] = random.nextDouble() < 0.9 ? 2 : 4;
    }
  }

  bool _canMove() {
    // Check for empty cells
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == 0) return true;
      }
    }
    // Check for possible merges
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        int current = grid[i][j];
        if (j < gridSize - 1 && grid[i][j + 1] == current) return true;
        if (i < gridSize - 1 && grid[i + 1][j] == current) return true;
      }
    }
    return false;
  }

  void _move(Direction direction) {
    if (gameOver) return;
    
    // 深拷贝当前网格状态用于比较
    List<List<int>> oldGrid = List.generate(
      gridSize, (i) => List.generate(gridSize, (j) => grid[i][j]),
    );
    mergedTiles.clear();
    bool moved = false;

    switch (direction) {
      case Direction.up:
        moved = _moveUp();
        break;
      case Direction.down:
        moved = _moveDown();
        break;
      case Direction.left:
        moved = _moveLeft();
        break;
      case Direction.right:
        moved = _moveRight();
        break;
    }

    // 检查网格是否真的发生了变化
    bool gridChanged = false;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (oldGrid[i][j] != grid[i][j]) {
          gridChanged = true;
          break;
        }
      }
      if (gridChanged) break;
    }

    // 只有在网格真正改变时才添加新方块
    if (moved && gridChanged) {
      _addRandomTile();
      if (!_canMove()) {
        gameOver = true;
      }
      if (score > bestScore) {
        bestScore = score;
      }
      setState(() {});
    }
  }

  bool _moveLeft() {
    bool moved = false;
    for (int i = 0; i < gridSize; i++) {
      // 获取非零元素
      List<int> row = [];
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] != 0) {
          row.add(grid[i][j]);
        }
      }
      
      // 合并相同的数字
      List<int> newRow = [];
      for (int j = 0; j < row.length; j++) {
        if (j + 1 < row.length && row[j] == row[j + 1]) {
          int merged = row[j] * 2;
          newRow.add(merged);
          score += merged;
          j++; // 跳过下一个已合并的元素
          moved = true;
        } else {
          newRow.add(row[j]);
        }
      }
      
      // 填充剩余位置为0
      while (newRow.length < gridSize) {
        newRow.add(0);
      }
      
      // 检查这一行是否发生了变化
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] != newRow[j]) {
          moved = true;
        }
      }
      
      grid[i] = newRow;
    }
    return moved;
  }

  bool _moveRight() {
    bool moved = false;
    for (int i = 0; i < gridSize; i++) {
      // 获取非零元素
      List<int> row = [];
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] != 0) {
          row.add(grid[i][j]);
        }
      }
      
      // 从右向左合并相同的数字
      List<int> newRow = [];
      for (int j = row.length - 1; j >= 0; j--) {
        if (j - 1 >= 0 && row[j] == row[j - 1]) {
          int merged = row[j] * 2;
          newRow.insert(0, merged);
          score += merged;
          j--; // 跳过下一个已合并的元素
          moved = true;
        } else {
          newRow.insert(0, row[j]);
        }
      }
      
      // 在左侧填充0
      while (newRow.length < gridSize) {
        newRow.insert(0, 0);
      }
      
      // 检查这一行是否发生了变化
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] != newRow[j]) {
          moved = true;
        }
      }
      
      grid[i] = newRow;
    }
    return moved;
  }

  bool _moveUp() {
    bool moved = false;
    for (int j = 0; j < gridSize; j++) {
      // 获取非零元素
      List<int> column = [];
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] != 0) {
          column.add(grid[i][j]);
        }
      }
      
      // 合并相同的数字
      List<int> newColumn = [];
      for (int i = 0; i < column.length; i++) {
        if (i + 1 < column.length && column[i] == column[i + 1]) {
          int merged = column[i] * 2;
          newColumn.add(merged);
          score += merged;
          i++; // 跳过下一个已合并的元素
          moved = true;
        } else {
          newColumn.add(column[i]);
        }
      }
      
      // 填充剩余位置为0
      while (newColumn.length < gridSize) {
        newColumn.add(0);
      }
      
      // 检查这一列是否发生了变化并更新网格
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] != newColumn[i]) {
          moved = true;
        }
        grid[i][j] = newColumn[i];
      }
    }
    return moved;
  }

  bool _moveDown() {
    bool moved = false;
    for (int j = 0; j < gridSize; j++) {
      // 获取非零元素
      List<int> column = [];
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] != 0) {
          column.add(grid[i][j]);
        }
      }
      
      // 从下向上合并相同的数字
      List<int> newColumn = [];
      for (int i = column.length - 1; i >= 0; i--) {
        if (i - 1 >= 0 && column[i] == column[i - 1]) {
          int merged = column[i] * 2;
          newColumn.insert(0, merged);
          score += merged;
          i--; // 跳过下一个已合并的元素
          moved = true;
        } else {
          newColumn.insert(0, column[i]);
        }
      }
      
      // 在顶部填充0
      while (newColumn.length < gridSize) {
        newColumn.insert(0, 0);
      }
      
      // 检查这一列是否发生了变化并更新网格
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] != newColumn[i]) {
          moved = true;
        }
        grid[i][j] = newColumn[i];
      }
    }
    return moved;
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 0: return const Color(0xFFCDC1B4);
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      default: return const Color(0xFF3C3A32);
    }
  }

  Color _getTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _move(Direction.up);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _move(Direction.down);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _move(Direction.left);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _move(Direction.right);
            }
          }
        },
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '2048',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF776E65),
                        ),
                      ),
                      Row(
                        children: [
                          _buildScoreBox('SCORE', score),
                          const SizedBox(width: 8),
                          _buildScoreBox('BEST', bestScore),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Instructions and New Game button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Join the numbers and get to the 2048 tile!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF776E65),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _initGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8F7A66),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'New Game',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Game Grid
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBADA0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: GestureDetector(
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity! < -100) {
                            _move(Direction.up);
                          } else if (details.primaryVelocity! > 100) {
                            _move(Direction.down);
                          }
                        },
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! < -100) {
                            _move(Direction.left);
                          } else if (details.primaryVelocity! > 100) {
                            _move(Direction.right);
                          }
                        },
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: gridSize * gridSize,
                          itemBuilder: (context, index) {
                            int row = index ~/ gridSize;
                            int col = index % gridSize;
                            int value = grid[row][col];
                            return _buildTile(value);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Controls hint
                  Text(
                    'Use arrow keys or swipe to move tiles',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (gameOver)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Game Over!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Final Score: $score',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF776E65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBox(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFEEE4DA),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(int value) {
    return Container(
      decoration: BoxDecoration(
        color: _getTileColor(value),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: value != 0
            ? Text(
                value.toString(),
                style: TextStyle(
                  fontSize: value < 100 ? 32 : (value < 1000 ? 28 : 24),
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(value),
                ),
              )
            : null,
      ),
    );
  }
}

enum Direction { up, down, left, right }