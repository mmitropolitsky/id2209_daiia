/***
* Name: festival
* Author: Viktoriya and Milko
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model festival

/* Insert your model definition here */

global {
	
	int numOfGuests -> {length (DancingGuest) + length(ChillingGuest)};
    int amusedGuests update: DancingGuest count (each.amused > 0.8) + ChillingGuest count (each.amused > 0.8);
	
	int numberOfGuests <- 10;
	int barsNum <- 5;
	int stageNum <- 5;
	int currentBarsNum -> {length(Bar)};
	
	list<string> musicTypes <- ["rock", "pop", "jazz"];

	init {
		create DancingGuest number: numberOfGuests;
		create ChillingGuest number: numberOfGuests;
		create Bar number: barsNum;
		create Stage number: stageNum;
	}
}

/**
 * Gues Species
 */
species Guest skills: [moving, fipa] {
	
	image_file my_icon;
	
	rgb myColor <- #red;
	float amused <- 0.0;
	int size <- 1;
	
	float goToBar <- 0.5;
	float goToStage <- 0.5;
	
	Stage currentStage <- nil;
	Bar currentBar <- nil;
	
	aspect info {
		draw sphere(size) at: location color: myColor border: #black;
		draw string(amused with_precision 2) size: 3 color: #black;
	}
	
	aspect icon {
		draw my_icon size: 2 * size;
	}
	
	reflex defaultBehaviour when: currentStage = nil and currentBar = nil {
		do wander;
		if (flip(goToStage)) {
			currentStage <- one_of(Stage);
		} else if (flip(goToBar)) {
			currentBar <- one_of(Bar);
		}
	}
	
	reflex goToStage when: currentStage != nil {
		do goto target: currentStage;
	}
	
	reflex goToBar when: currentBar != nil {
		do goto target: currentBar;
	}
	
	reflex isAtBar when: currentBar != nil and location = currentBar.location {
		write name + " is located at bar " + currentBar.name;
	}
	
	reflex isAtStage when: currentStage != nil and location = currentStage.location {
		write name + " is located at stage " + currentStage.name;
	}
}

species DancingGuest parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/dancer-icon-25.jpg");
	
	float adventurous <- rnd(0.5, 1.0);
	float confident <- rnd(0.5, 1.0);
	
	reflex meetChillingGuestsAtTheBar when: ChillingGuest at_distance(1) != nil {
		list<ChillingGuest> chillingGuestsMet <- ChillingGuest at_distance(1);
		loop g over: chillingGuestsMet {
			write name + ' met guest ' + g.name;
			do start_conversation to: [g] protocol: 'fipa-contract-net' performative: 'inform' contents: ["Let's go dancing"];
		}
	}
}

species ChillingGuest parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/chilling-person.jpg");
	
	float cautious <- rnd(0.5, 1.0);
	float nervous <- rnd(0.1, 0.3);
}

species Stage skills: [fipa] {
	image_file my_icon <- image_file("../includes/data/stage.png");
	
	rgb stageColor <- #green;
	string musicType <- musicTypes[rnd(2)];
	
	aspect info {
		draw square(5) at: location color: #transparent border: stageColor;
		draw string("Music type: " + musicType) size: 3 color: stageColor;
	}
	
	aspect icon {
		draw my_icon size: 5;
	}
}

species Bar skills: [fipa] {
	
	image_file my_icon <- image_file("../includes/data/bar.png");
	
	rgb barColor <- #blue;
	int beer <- 100;
	
	aspect info {
		draw square(5) at: location color: #transparent border: barColor;
		draw string("Beers: " + beer) size: 3 color: barColor;
	}
	
	aspect icon {
		draw my_icon size: 5;
	}
}

experiment fest_experiment type: gui {
//	parameter "Initial number of bars: " var: barsNum category: "Fun places at the festival" ;
	output {
		display main_display {
            species Guest aspect: icon;
			species DancingGuest aspect: icon;
			species ChillingGuest aspect: icon;
			species Bar aspect: icon;
			species Stage aspect: icon;
        }

        display info_display {
            species Guest aspect: info;
			species DancingGuest aspect: info;
			species ChillingGuest aspect: info;
			species Bar aspect: info;
			species Stage aspect: info;
        }
		
//		display chart refresh: every(10#cycles) {
//	        chart "Interesting value 1" type: series style: spline {
//	        	data "allGuests" value: allGuests color: #green;
//	        	data "amusedGuests" value: amusedGuests color: #red;
//	        }
//    	}	
//    	monitor "Number of amused guests: " value: amusedGuests;
//    	monitor "All guests: " value: numOfGuests;
	}
	
	
}

