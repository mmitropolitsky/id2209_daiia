/***
* Name: eightqueens
* Author: Viktoriya
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model eightqueens
/* Insert your model definition here */

global{
    int boardSize <- 4;
    
    init {
    	
    	create Queen number: boardSize returns: queensList;
    	
    	loop i from: 0 to: boardSize - 1 step: 1 {
    		if (i = 0) {
    			Queen q <- queensList[i];
    			q.row <- 0;

    			q.column <- rnd(0, (boardSize - 1), 1);
    			write 'first queen column ' + q.column;
    			
    		} else {
    			Queen q <- queensList[i];
    			q.row <- i;
    			q.column <- -1;
    			Queen previousQ <- queensList[i - 1];
    			q.predecessor <- previousQ;
    			previousQ.successor <- q;
    			q.location <- {0,0};
    		}
    	}
    	
    	//start the alg
    	Queen q <- queensList[0];
		ask q {
			do moveToFreePosition(q.column);
		}
    	
    }	
}

species Queen skills: [fipa] {
	
	action setCell {
		write 'in queen init';
		location <- ChessBoard[column, row] as point;
		do markCellsAsOccupied;
	}
	
	int row;
	int column;
	bool positioned <- false;
	bool isNotified <- false;
	list<point> previousPositions;
	
	Queen predecessor;
	Queen successor;
	
	reflex receiveNotificationWhenNotPositioned when: !empty(informs) and !positioned and time mod 2  = 1 {
		loop i over:informs {
			if (i.sender = predecessor) {
				write name + ' notified from predecessor ' + predecessor;
				do end_conversation message: i contents: ['Working on it'];
				do occupyCells;
			}
		}
	}
	
	reflex receiveNotificationWhenPositioned when: !empty(informs) and positioned and time mod 3 = 1 {
		loop i over:informs {
			if (i.sender = successor) {
				write name + ' notified from successor ' + successor;
				do end_conversation message: i contents: ['I will reposition'];
				do repositionIfPossible;
			}
		}
	}
	
	action repositionIfPossible {
		write name + ' deoccupy cells';
		positioned <- false;
		do markCellsAsUnoccupied;
		do occupyCells;
	}
	
	action occupyCells {
		write name + " enter occupy function";
		loop i from: 0 to: boardSize - 1 step: 1 {
			ChessBoard cb <- ChessBoard grid_at {i, row};
			write name + 'checking cell ' + cb + ' with occupation ' + cb.occupied;
			// there is a free position on my row
			if (!(previousPositions contains {i, row}) and cb.occupied = 0) {
				do moveToFreePosition(i);
				break;
			}
		}
		
		// there is no free position on my row
		if (!positioned) {
			if (predecessor != nil) {
				write "Time(" + time + "): " + name + " notifies predecessor " + predecessor;
				previousPositions <- [];
				location <- {0,0};
				do start_conversation to: [predecessor] protocol: 'no-protocol' performative: 'inform' contents: ['Reposition'] ;
			}
		}
	}
	
	action moveToFreePosition(int i) {
		write name + 'My current position is (c,r): ' + column + ', ' + row + ". New possible position: " + {i, row}; 
		location <- ChessBoard[i, row] as point;
		column <- i;

		positioned <- true;
		add {column, row} to: previousPositions;
		
		write name + ' predecessor: ' + predecessor + '; successor: ' + successor + '; my row is: ' + row + "; my column is: " + column;
		do markCellsAsOccupied;
		
		//TODO check if the last element has been successfully positioned - then stop
		if (successor != nil and !successor.positioned) {
			write 'Successor ' + successor + ' position is ' + successor.positioned;
			write "Time(" + time + "): " + name + " notifies successor " + successor;
			do start_conversation to: [successor] protocol: 'no-protocol' performative: 'inform' contents: ['Position'] ;
		}
	}
	
	action markCellsAsOccupied {
		loop i from: 0 to: boardSize - 1 step: 1 {
			loop j from: 0 to: boardSize - 1 step: 1 {
				if (j != row and i != column) {
					if (j = row) {
						do doOccupy(i,j);
					}
					
					if (i = column) {
						do doOccupy(i,j);
					} 
					
					if (abs(j - row) = abs (i - column)){
						do doOccupy(i,j);
					}
				} else {
					do doOccupy(i,j);
				}
			}
		}
	} 
	
	action doOccupy(int i, int j) {
		ask ChessBoard grid_at {i, j} {
			self.occupied <- self.occupied + 1;
        }
	}
	
	action markCellsAsUnoccupied {
		write name + " enter unoccupy function";
		loop i from: 0 to: boardSize - 1 step: 1 {
			loop j from: 0 to: boardSize - 1 step: 1 {
//				write "Checking i:" + i + ", j: " + j;
				
				if (j = row) {
					do doUnoccupy(i,j);
				}
				
				if (i = column) {
					do doUnoccupy(i,j);
				} 
				
				if (abs(j - row) = abs (i - column)){
					do doUnoccupy(i,j);
				}

			}
		}
	}
	
	action doUnoccupy(int i, int j) {
		ask ChessBoard grid_at {i, j} {
//			write myself.name + ' is unoccupying a cell that maybe is unoccupied';
			if (self.occupied > 0) {
				self.occupied <- self.occupied - 1;
			}
        }
	}
	
    aspect default {
    	draw circle(1) color: #blue;
    }
    
}

grid ChessBoard width: boardSize height: boardSize {
	int occupied;
	
	reflex changeColor {
		if (self.occupied = 0) {
			self.color <- #white;
		} else if (self.occupied = 1) {
			self.color <- #yellow;
		} else if (self.occupied = 2) {
			self.color <- #orange;
		} else if (self.occupied = 3) {
			self.color <- #red;	
		} else if (self.occupied >= 4) {
			self.color <- #purple;
		}
	}
}

experiment NQueensProblem type: gui{
    output {
	    display map {
	        grid ChessBoard lines: #black ;
	        species Queen;
	    }
    }
}

