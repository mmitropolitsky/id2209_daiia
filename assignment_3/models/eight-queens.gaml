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
    	create Queen {
    		location <- ChessBoard[2, 2] as point;
    		row <- 2;
    		column <- 2;
    	}
    }	
}

species Queen {
	
	int row;
	int column;
	
	reflex occupyCells {
//		ask ChessBoard grid_at {0, 0} {
//			write 'test ask';
//			if(self overlaps myself) {
//				write 'I am on the grid';
//	            self.occupied <- 2;
//	        } else if (self.occupied != 2) {
//	            self.occupied <- 1;
//	        }
//	        do update_occupation;
//		}
		do isSafe;
	}
	
	action isSafe {
		loop i from: 0 to: boardSize - 1 step: 1 {
			loop j from: 0 to: boardSize - 1 step: 1 {
				write "Checking i:" + i + ", j: " + j;
				
				if (i = row) {
					do doOccupy(i,j);
				}
				
				if (j = column) {
					do doOccupy(i,j);
				} 
				
				if (abs(i - row) = abs (j - column)){
					do doOccupy(i,j);
				}

			}
		}
	} 
	
	action doOccupy(int i, int j) {
		ask ChessBoard grid_at {i, j} {
			write 'test ask';
			if(self overlaps myself) {
				write 'I am on the grid';
            	self.occupied <- 2;
        	} else if (self.occupied != 2) {
            	self.occupied <- 1;
        	}
        	do update_occupation;
        }
	}
	
    aspect default {
    	draw circle(1) color: #blue;
    }
    
}

grid ChessBoard width: boardSize height: boardSize {
	int occupied;
	
	action update_occupation {
	    if (occupied = 0) {
	        color <- #green;
	    } else if (occupied > 0) {
	        color <- #red;
	    }
    	occupied <- 0;
    }
    // my_grid has 8 columns and 10 rows
}

experiment main_xp type: gui{
    output {
	    display map {
	        grid ChessBoard lines: #black ;
	        species Queen;
	    }
    }
}

