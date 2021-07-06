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
            let cell = Cell(board: board, index: i)
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

    func addToEmptyCells(_ cell: Cell) {
        if emptyCells.count == 0 { emptyCells.append(cell) }
        if cell.index > emptyCells.last!.index { emptyCells.append(cell) }

        var arrayIndex = 0
        while cell.index > emptyCells[arrayIndex].index { arrayIndex += 1 }
        emptyCells.insert(cell, at: arrayIndex)
    }

    func removeFromEmptyCells(_ cell: Cell) {
        if let itemIndex = emptyCells.firstIndex(of: cell) {
            emptyCells.remove(at: itemIndex)
        }
    }

    func hasEmptyCells() -> Bool {
        return emptyCells.count == 0
    }

    func printBoard() {
        for (i, row) in rows.enumerated() {
            if i % 3 == 0 {
                print("+===+===+===+===+===+===+===+===+===+")
            } else {
                print("+---+---+---+---+---+---+---+---+---+")
            }
            print("/", terminator: "")
            for (j, cell) in row.cells.enumerated() {
                let colDelimiter = j % 3 == 2 ? "/" : "|"
                print(" \(cell.valueString) \(colDelimiter)", terminator: "")
            }
            print()
        }
        print("+---+---+---+---+---+---+---+---+---+")
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
    var possibleValues: Set<Int>
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

    func resetPossibleValues() {
        possibleValues = row.unusedValues.intersection(col.unusedValues).intersection(house.unusedValues)
    }
}

//MARK: Initialization
var board = Board()
for (i, row) in board.rows.enumerated() {
    print("Row \(i + 1): Please enter the numbers from (L -> R). Mark unknown cells as '*'.")
    printInsertionPoint()

    var rowString = readLine()!
    while rowString.count != 9 {
        print("You must eneter 1-9 or * for each cell in the row.")
        printInsertionPoint()
        rowString = readLine()!
    }

    let cellStrings = Array(rowString)

    for (j, cell) in row.cells.enumerated() {
        cell.currentValue = cellStrings[j].wholeNumberValue
        if cell.currentValue != nil {
//            cell.possibleValues = [cell.currentValue!]
            cell.locked = true
            cell.removeCurrentValueFromUnusedValues()
            board.removeFromEmptyCells(cell)
        }
    }
}

//MARK: Solving
func solveNextCell() {
    let currentCell = board.emptyCells.removeFirst()
    board.attemptedCells.append(currentCell)

    var possibleVals = Array(currentCell.possibleValues)
    for value in possibleVals {
        currentCell.currentValue = value
        currentCell.removeCurrentValueFromUnusedValues()
    }
    if board.isSolved() == .solved { return }
}
