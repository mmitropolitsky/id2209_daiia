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

    			q.column <- 0; //rnd(0, (boardSize - 1), 1);
    			write 'first queen column ' + q.column;
    			q.positioned <- true;
  
    			ask q {
    				do setCell;
    			}
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
	point previousPosition;
	
	Queen predecessor;
	Queen successor;
	
	reflex trackChessBoardOccupation {
		loop cell over: ChessBoard {
			write cell.name + ' occupation ' + cell.occupied;
		}
	}
	
	reflex notifySuccessor when: positioned {
		if (successor != nil) {
			write "Time(" + time + "): " + name + " notifies successor " + successor;
			do start_conversation to: [successor] protocol: 'no-protocol' performative: 'inform' contents: ['Position'] ;
		}
	}
	
	reflex receiveNotificationWhenNotPositioned when: !empty(informs) and !positioned {
//		write name + ' receieve notification when not positioned';
		loop i over:informs {
			if (i.sender = predecessor) {
				write name + ' notified from ' + predecessor;
				do occupyCells;
			} else if (i.sender = successor) {
//				write 'Wrong occurence in successor';
				//TODO
			}
		}
	}
	
	reflex receiveNotificationWhenPositioned when: !empty(informs) and positioned {
//		write name + ' receieve notification when positioned';
		loop i over:informs {
			if (i.sender = successor) {
				write name + ' deoccupy cells';
				do markCellsAsUnoccupied;
				do occupyCells;
			} else if (i.sender = predecessor) {
//				write 'Wrong occurence in predecessor';
				//TODO
			}
		}
	}
	
	action occupyCells {
		write name + " enter occupy function";
		loop i from: 0 to: boardSize - 1 step: 1 {
			ChessBoard cb <- ChessBoard grid_at {i, row};
			write name + 'checking cell ' + cb + ' with occupation ' + cb.occupied;
			// there is a free position on my row
//			point currentPoint <- {i, row}; //ChessBoard[i, row] as point;
			if (previousPosition != {i, row} and cb.occupied = 0) {
				write name + 'My current position is (c,r): ' + column + ', ' + row + ". New possible position: " + {i, row}; 
				location <- ChessBoard[i, row] as point;
				column <- i;

				positioned <- true;
				previousPosition <- {i, row};
				
				write name + ' predecessor: ' + predecessor + '; successor: ' + successor + '; my row is: ' + row + "; my column is: " + column;
				do markCellsAsOccupied;
			}
		}
		// there is no free position on my row
		if (!positioned) {
			if (predecessor != nil) {
				write "Time(" + time + "): " + name + " notifies predecessor " + predecessor;
				do start_conversation to: [predecessor] protocol: 'no-protocol' performative: 'inform' contents: ['Reposition'] ;
			}
		}
	}
	
	action markCellsAsOccupied {
		loop i from: 0 to: boardSize - 1 step: 1 {
			loop j from: 0 to: boardSize - 1 step: 1 {
//				write "Checking i:" + i + ", j: " + j;
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
//        	do update_occupation;
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
			
//        	do update_occupation;
        }
	}
	
    aspect default {
    	draw circle(1) color: #blue;
    }
    
}

grid ChessBoard width: boardSize height: boardSize {
	int occupied;
	
	reflex changeColor {
		if (self.occupied = 1) {
			self.color <- #yellow;
		} else if (self.occupied = 2) {
			self.color <- #orange;
		} else if (self.occupied = 3) {
			self.color <- #red;	
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

