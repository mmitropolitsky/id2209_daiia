/***
* Name: highestutilitystage
* Author: Viktoriya and Milko
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model highestutilitystage

/* Insert your model definition here */
global {
	init {
		create Guest number: 1;
		create Stage number: 4;
		
	}
}

species Stage skills: [fipa] {
	
	float lightShow;
	float speakers;
	float band;
	float fireworks;
	float sittingSpots;
	float toiletsNearby;
	
//	reflex startShow {
//		do initializeShowParameters;
//		list<Guest> allGuests <- Guest at_distance(100);
//		if (allGuests != nil and !empty(allGuests)) {
//			map<string, float> showParameters <- initializeShowParameters;
//			write "Time (" + time + "): " + name + " is starting a new show.";
//			do start_conversation to:  allGuests protocol: 'fipa-contract-net' performative: 'inform' contents: [showParameters] ;
//		}
//	}
	
	map<string, float> initializeShowParameters {
		write "Time (" + time + "): " + name + " start hosting an act.";
		lightShow <- rnd(0.1, 0.9);
		speakers <- rnd(0.1, 0.9);
		band <- rnd(0.1, 0.9);
		fireworks <- rnd(0.1, 0.9);
		sittingSpots <- rnd(0.1, 0.9);
		toiletsNearby <- rnd(0.1, 0.9);
		write name + " parameters: lightShow " + lightShow + "; speakers: " + speakers + "; band: " + band
			+ " ; fireworks: " + fireworks + "; sittingSpots: " + sittingSpots + "; toiletsNearby: " + toiletsNearby;
		return map<string, float>("lightShow"::lightShow, "speakers"::speakers, "band"::band, 
			"fireworks"::fireworks, "sittingSpots"::sittingSpots, "toiletsNearby"::toiletsNearby);
	}
	
	rgb stageColor <- #green;
	
	aspect default {
		draw pyramid(5) at: location color: stageColor;
	}
}

species Guest skills: [moving, fipa] {
	
	list<Stage> stages <- Stage at_distance(100);
	
	float lightShow <- 0.2;
	float speakers <- 0.8;
	float band <- 0.9;
	float fireworks <- 0.1;
	float sittingSpots <- 0.3;
	float toiletsNearby <- 0.5;
	
	action goToPreferredStage {
		Stage stageWithMaxUtility <- stages with_max_of (calculateStageUtilityFunction(each));
		do goto target:stageWithMaxUtility;
	}
	
	float calculateStageUtilityFunction(Stage stage) {
		float utility <- lightShow * stage.lightShow 
			+ speakers * stage.speakers 
			+ band * stage.band 
			+ fireworks * stage.fireworks
			+ sittingSpots * stage.sittingSpots
			+ toiletsNearby * stage.toiletsNearby;
		write 'Time (' + time + ' ): ' + stage.name + ' has utility ' + utility + ' for guest ' + name;
		return utility;
	}
	
	rgb myColor <- #red;
	
	reflex dance {
		do wander;
	}
	
	aspect default {
		draw sphere(1) at: location color: myColor;
	}
}

experiment highestutilitystage_experiment type: gui {
	output {
		display displayFest type: opengl {
			species Guest;
			species Stage;
		}	
	}
}