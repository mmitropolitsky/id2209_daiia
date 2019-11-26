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
		create Guest number: 20;
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
	
	bool startAConcert;
	int showDuration <- -1;
	int showTimer <- 0;
	
	reflex startShow when: !startAConcert {
		startAConcert <- flip(0.2);
		if(startAConcert) {
			do announceShow;
		}
	}

	action announceShow {
		do initializeShowParameters;
		do informGuestsThatShowIsStarting;
	}
	
	action initializeShowParameters {
		showDuration <- rnd(75, 90);
		write "Time (" + time + "): " + name + " start hosting a show with duration " + showDuration;
		lightShow <- rnd(0.1, 0.9) with_precision 1;
		speakers <- rnd(0.1, 0.9) with_precision 1;
		band <- rnd(0.1, 0.9) with_precision 1;
		fireworks <- rnd(0.1, 0.9) with_precision 1;
		sittingSpots <- rnd(0.1, 0.9) with_precision 1;
		toiletsNearby <- rnd(0.1, 0.9) with_precision 1;
		write name + " parameters: lightShow " + lightShow + "; speakers: " + speakers + "; band: " + band
			+ " ; fireworks: " + fireworks + "; sittingSpots: " + sittingSpots + "; toiletsNearby: " + toiletsNearby;
	}
	
	action informGuestsThatShowIsStarting {
		list<Guest> allGuests <- Guest at_distance(100);
		if (allGuests != nil and !empty(allGuests)) {
			map<string, float> parametersMap <- map<string, float>("lightShow"::lightShow, "speakers"::speakers, "band"::band, 
			"fireworks"::fireworks, "sittingSpots"::sittingSpots, "toiletsNearby"::toiletsNearby);
			write parametersMap;
			write "Time (" + time + "): " + name + " send msg about show with duration " + showDuration;
			do start_conversation to:  allGuests protocol: 'fipa-contract-net' performative: 'inform' contents: [parametersMap] ;
		}
	}
	
	reflex endShow when: showDuration = showTimer {
		write "Time (" + time + "): " + name + " is ending the show.";
		startAConcert <- false;
		showDuration <- -1;
		showTimer <- 0;
		
		do informGuestsThatShowIsEnding;
	}
	
	action informGuestsThatShowIsEnding {
		list<Guest> guestsAttendingShow <- Guest at_distance(0); //guest that are in the square
		if (guestsAttendingShow != nil and !empty(guestsAttendingShow)) {
			do start_conversation to: guestsAttendingShow protocol: 'fipa-request' performative: 'request' contents: ['Get out of venue'];
			write name + " informs guests " + guestsAttendingShow + " that show is ending.";
		}
	}
	
	// keep the order of endShow reflex and handleShowDuration - this way when we update the show timer on the next round it will end it.
	reflex handleShowDuration when: startAConcert {
		showTimer <- showTimer + 1;
	} 
	
	rgb stageColor <- #green;
	
	aspect default {
		draw pyramid(5) at: location color: stageColor;
	}
}

species Guest skills: [moving, fipa] {
	
	float lightShow <- rnd(0.1, 0.9) with_precision 1;
	float speakers <- rnd(0.1, 0.9) with_precision 1;
	float band <- rnd(0.1, 0.9) with_precision 1;
	float fireworks <- rnd(0.1, 0.9) with_precision 1;
	float sittingSpots <- rnd(0.1, 0.9) with_precision 1;
	float toiletsNearby <- rnd(0.1, 0.9) with_precision 1;
	
	bool isAttendingAStage <- false;
	Stage attendedStage;
	
	reflex read_inform when: !empty(informs) and !isAttendingAStage {
		list<Stage> stages <- informs collect (each.sender);
		
		Stage stageWithMaxUtility <- stages with_max_of (calculateStageUtilityFunction(each));
		write 'Stage with max utility is ' + stageWithMaxUtility.name;
		attendedStage <- stageWithMaxUtility;
		isAttendingAStage <- true;
		
		loop i over: informs {
			Stage stage <- i.sender;
			write '(Time ' + time + '): ' + name + ' receives message with content: ' + (string(i.contents));
			do end_conversation message: i contents: ['Understood message from ' + agent(i.sender).name];
		}
	}
	
	float calculateStageUtilityFunction(Stage stage) {
		float utility <- (lightShow * stage.lightShow 
			+ speakers * stage.speakers 
			+ band * stage.band 
			+ fireworks * stage.fireworks
			+ sittingSpots * stage.sittingSpots
			+ toiletsNearby * stage.toiletsNearby) with_precision 1;
		write 'Time (' + time + ' ): ' + stage.name + ' has utility ' + utility + ' for guest ' + name;
		return utility;
	}
	
	reflex read_show_is_ending_message when: !empty(requests) and isAttendingAStage {
		write '(Time ' + time + '): ' + name + ' receives request to leave stage.';
		loop r over: requests {
			Stage stage <- r.sender as Stage;
			write '(Time ' + time + '): ' + name + ' receives message with content: ' + (string(r.contents));
			do agree message: r contents: ['I am going away'];
			isAttendingAStage <- false;
		}
	}
	
	reflex goToPreferredStage when: isAttendingAStage {
		do goto target:attendedStage; 
	}
	
	reflex dance when: !isAttendingAStage {
		do wander;
	}
	
	rgb myColor <- #red;
	
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