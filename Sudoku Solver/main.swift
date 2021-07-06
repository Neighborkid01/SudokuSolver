//
//  main.swift
//  Sudoku Solver
//
//  Created by Millennium Falcon on 7/5/21.
//

import Foundation

//MARK: Helpers
let oneToNine = [1, 2, 3, 4, 5, 6, 7, 8, 9]

func printInsertionPoint() {
    print("-> ", terminator: "")
}

// From: https://stackoverflow.com/questions/25006235/how-to-benchmark-swift-code-execution
func printTimeElapsedWhenRunningCode(title:String, operation:()->()) {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed for \(title): \(timeElapsed) s.")
}

func timeElapsedInSecondsWhenRunningCode(operation: ()->()) -> Double {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    return Double(timeElapsed)
}

//MARK: Classes
enum SolveStates {
    case emptyCells
    case duplicateValue
    case solved
}

class Board {
    var allCells = [Cell]()
    var emptyCells = [Cell]()
    var attemptedCells = [Cell]()
    var rows = [Row]()
    var cols = [Col]()
    var houses = [House]()

    init() {
        for i in 0..<81 {
            let cell = Cell(board: self, index: i)
            allCells.append(cell)
            emptyCells.append(cell)
        }

        for i in 0..<9 {
            // Createing rows
            let rowRange = (i * 9)..<((i + 1) * 9)
            rows.append(Row(cells: Array(allCells[rowRange])))

            // Creating col
            let colIndicies = oneToNine.map { 9 * ($0 - 1) + i }
            var colCells = [Cell]()
            for i in colIndicies { colCells.append(allCells[i]) }
            cols.append(Col(cells: colCells))

            // Creating house
            var currentIndex: Int
            var houseCells = [Cell]()
            for j in 0..<3 { // sub-rows
                for k in 0..<3 { // sub-cols
                    //             start row     + start col + inner row + inner col
                    currentIndex = (((i/3)*3)*9) + ((i%3)*3) + (j*9)     + (k)
                    houseCells.append(allCells[currentIndex])
                }
            }
            houses.append(House(cells: houseCells))
        }
    }

    func isSolved() -> SolveStates {
        if hasEmptyCells() { return .emptyCells }

        // Checking for solved rows
        for row in rows {
            let solveState = row.isSolved()
            if solveState != .solved { return solveState }
        }

        // Checking for solved cols
        for col in cols {
            let solveState = col.isSolved()
            if solveState != .solved { return solveState }
        }

        // Checking for solved houses
        for house in houses {
            let solveState = house.isSolved()
            if solveState != .solved { return solveState }
        }

        return .solved
    }

    func removeFromEmptyCells(_ cell: Cell) {
        if let itemIndex = emptyCells.firstIndex(of: cell) {
            emptyCells.remove(at: itemIndex)
        }
    }

    func hasEmptyCells() -> Bool {
        return emptyCells.count > 0
    }

    func toString() -> String {
        var output = ""
        for (i, row) in rows.enumerated() {
            if i % 3 == 0 {
                output += "+===+===+===+===+===+===+===+===+===+\n"
            } else {
                output += "+---+---+---+---+---+---+---+---+---+\n"
            }
            output += "/"
            for (j, cell) in row.cells.enumerated() {
                let colDelimiter = j % 3 == 2 ? "/" : "|"
                output += " \(cell.valueString) \(colDelimiter)"
            }
            output += "\n"
        }
        output += "+===+===+===+===+===+===+===+===+===+"
        
        return output
    }
    
    func printBoard() {
        print(toString())
    }

    func printRows() {
        for row in rows {
            print(row.cellValues)
        }
    }
    
    func printCols() {
        for col in cols {
            print(col.cellValues)
        }
    }

    func printHouses() {
        for house in houses {
            print(house.cellValues)
        }
    }
}

class CellGroup {
    var cells = [Cell]()
    var cellValues: [Int?] { cells.map { $0.currentValue == nil ? nil : $0.currentValue! } }
    var unusedValues = Set(oneToNine)

    init(cells: [Cell]) {
        self.cells = cells
    }

    func isSolved() -> SolveStates {
        if hasDuplicateNumber() { return .duplicateValue }
        return .solved
    }

    func hasDuplicateNumber() -> Bool {
        return cells.count > Set(cellValues).count
    }
}

class Row: CellGroup {
}

class Col: CellGroup {
}

class House: CellGroup {
}

class Cell: Equatable {
    var index: Int
    var rowIndex: Int { index / 9 }
    var colIndex: Int { index % 9 }
    var houseIndex: Int { ((rowIndex / 3) * 3) + (colIndex / 3) }

    var board: Board
    var row: Row { board.rows[rowIndex] }
    var col: Col { board.cols[colIndex] }
    var house: House { board.houses[houseIndex] }

    var currentValue: Int?
    var isEmpty: Bool { currentValue == nil }
    var possibleValues = Set<Int>()
    var attemptedValues = [Int]()
//    var possibleValues = oneToNine
    var locked = false

    var valueString: String { currentValue == nil ? " " : String(currentValue!) }

    init(board: Board, index: Int) {
        self.board = board
        self.index = index
    }

    static func == (lhs: Cell, rhs: Cell) -> Bool {
        lhs.index == rhs.index
    }

    func removeCurrentValueFromUnusedValues() {
        if currentValue == nil { return }
        row.unusedValues.remove(currentValue!)
        col.unusedValues.remove(currentValue!)
        house.unusedValues.remove(currentValue!)
    }
    
    func addCurrentValueToUnusedValues() {
        if currentValue == nil { return }
        row.unusedValues.insert(currentValue!)
        col.unusedValues.insert(currentValue!)
        house.unusedValues.insert(currentValue!)
    }

    func resetPossibleValues() {
        possibleValues = row.unusedValues.intersection(col.unusedValues).intersection(house.unusedValues)
    }
}

//MARK: Initialization
func createBoard(from boardString: String?) -> Board {
    let shouldReadInput = boardString == nil
    var boardStrings = [String.SubSequence]()
    
    let board = Board()
    var rowString: String
    if !shouldReadInput { boardStrings = boardString!.split(separator: "\n") }
    for (i, row) in board.rows.enumerated() {
        if shouldReadInput {
            print("Row \(i + 1): Please enter the numbers from (L -> R). Mark unknown cells as '*'.")
            printInsertionPoint()
            rowString = readLine()!
        } else {
            rowString = String(boardStrings[i])
        }
        
        while rowString.count != 9 {
            print("You must eneter 1-9 or * for each cell in the row.")
            printInsertionPoint()
            rowString = readLine()!
        }

        let cellStrings = Array(rowString)

        for (j, cell) in row.cells.enumerated() {
            cell.currentValue = cellStrings[j].wholeNumberValue
            if cell.currentValue != nil {
                cell.locked = true
                cell.removeCurrentValueFromUnusedValues()
                board.removeFromEmptyCells(cell)
            }
        }
    }
    
    return board
}


@discardableResult func solveNextCell(forBoard board: Board) -> Bool {
    let currentCell = board.emptyCells.removeFirst()
    board.attemptedCells.append(currentCell)

    currentCell.resetPossibleValues()
    let possibleVals = Array(currentCell.possibleValues)
    for value in possibleVals {
        currentCell.currentValue = value
        currentCell.removeCurrentValueFromUnusedValues()
        
        if board.hasEmptyCells() {
            if solveNextCell(forBoard: board) == true { return true }
        } else if board.isSolved() == .solved {
            return true
        }

        currentCell.addCurrentValueToUnusedValues()
    }

    currentCell.currentValue = nil
    board.attemptedCells.removeLast()
    board.emptyCells.insert(currentCell, at: 0)
    return false
}

let n = 1000
let inputString = "1****87**\n96***3**8\n78****5**\n**189****\n4***1***5\n*****7***\n********2\n***5***91\n**82****3"
var boardString = ""
var times = [Double]()

for i in 1...n {
    if i % (n/10) == 0 { print("\(Double(i*100)/Double(n))%...") }
    let board = createBoard(from: inputString)
    let elapsedTime = timeElapsedInSecondsWhenRunningCode {
        solveNextCell(forBoard: board)
    }
    times.append(elapsedTime)
    
    if i == n { boardString = board.toString() }
}

let totalTime = times.reduce(0, +)
let averageTime = totalTime/Double(times.count)
let minTime = times.min()!
let maxTime = times.max()!

print("\n\n\n")
for (i, time) in times.enumerated() {
    print("Run \(i+1))\t\(time)s")
}
print("----------------------------------------------")
print("Max time:   \(maxTime)s")
print("Min time:   \(minTime)s")
print("Total time: \(totalTime)s")
print("Avg time:   \(averageTime)s")
print("\n\n\(boardString)")
