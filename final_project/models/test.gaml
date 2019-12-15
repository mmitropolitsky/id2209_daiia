/***
* Name: test
* Author: Viktoriya
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model test

/* Insert your model definition here */

global {
	
	int nb_preys_init <- 5;
	
	init {
        create prey number: nb_preys_init;
    }
}

species prey {
    rgb color <- #blue;
    image_file my_icon <- image_file("../includes/data/turtle.png");
    float size <- 1.0;
    
    
    aspect icon {
        draw my_icon size: 2 * size;
    }

    aspect info {
        draw square(size) color: color;
        draw string(2.567 with_precision 2) size: 3 color: #black;
    }
}


experiment prey_predator type: gui {
    parameter "Initial number of preys: " var: nb_preys_init min: 0 max: 1000 category: "Prey";
    
    output {
        display main_display {
            species prey aspect: icon;
//            species predator aspect: icon;
        }

        display info_display {
            species prey aspect: info;
//            species predator aspect: info;
        }
      
    }
}



