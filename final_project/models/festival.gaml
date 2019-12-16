/***
* Name: festival
* Author: Viktoriya and Milko
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model festival

/* Insert your model definition here */

global {
	
	string NO_MORE_BEER -> "I do not have more beer";
	string BEER_IN_STOCK -> "Here you are!";
	string SECURITY_GUARD_HEADING_TO_YOU <- "I will catch you!";
	string SECURITY_GUARD_CAUGHT_YOU <- "Go to prison.";
	
	int numOfGuests -> {length (DancingGuest) + length(ChillingGuest)};
    int amusedGuests update: DancingGuest count (each.happiness > 0.8) + ChillingGuest count (each.happiness > 0.8);
	
	int numberOfGuests <- 5;
	int barsNum <- 5;
//	int stageNum <- 5;
	int currentBarsNum -> {length(Bar)};
	
	point prisonLocation <- {90.0, 90.0};
	
	list<string> musicTypes <- ["rock", "pop", "jazz"];

	init {
		create DancingGuest number: numberOfGuests;
//		create ChillingGuest number: numberOfGuests;
//		create Photographer number: numberOfGuests;
		create Bar number: barsNum;
		create SecurityGuard number: numberOfGuests / 5;
		create Prison number: 1;
//		create Stage number: stageNum;
	}
}

/**
 * Gues Species
 */
species Guest skills: [moving, fipa] {
	
	image_file my_icon;
	
	rgb myColor <- #red;
	float happiness <- 0.0 with_precision 2;
	float drunkness <- 0.0 with_precision 2;
	float loudness <- rnd(0.5, 1.0) with_precision 2;
	
	int size <- 1;
	
	float goToBar <- 0.5 with_precision 2;
	float goToStage <- 0.5 with_precision 2;
	bool goToPrison <- false;
	
	Stage currentStage <- nil;
	Bar currentBar <- nil;
	
	int timeAtBar <- 30 update: isAtBar() ? timeAtBar - 1 : timeAtBar min: 0;
	int timeAtStage <- 30 update: isAtStage() ? timeAtStage - 1 : timeAtStage min: 0;
	int timeAtPrison <- 10 update: isAtPrison() ? timeAtPrison - 1 : timeAtPrison min: 0;
	
	aspect info {
		draw sphere(size) at: location color: myColor border: #black;
		draw string(happiness with_precision 2) size: 3 color: #black;
	}
	
	aspect icon {
		draw my_icon size: 2 * size;
	}
	
	reflex defaultBehaviour when: currentStage = nil and currentBar = nil {
		do wander;
		if (goToPrison) {
			do goto target: one_of(Prison);
		} else if (flip(goToStage)) {
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
	
	reflex isAtBar when: isAtBar() {
		if (timeAtBar = 0) {
			timeAtBar <- 30;
			currentBar <- nil;
		}
	}
	
	action endTimeAtBar {
		timeAtBar <- 30;
		currentBar <- nil;
	}
	
	bool isAtBar {
		return currentBar != nil and location = currentBar.location;
	}
	
	reflex isAtStageReflex when: isAtStage() {
		if (timeAtStage = 0) {
			timeAtStage <- 30;
			currentStage <- nil;
		}
	}
	
	bool isAtStage {
		return currentStage != nil and location = currentStage.location;
	}
	
	bool isAtPrison {
		Prison prison <- one_of(Prison);
		list<agent> agentsInPrison <- agents_overlapping(prison);
		return agentsInPrison contains self;
	}
	
	bool isBad {
		return drunkness > 0.8 and loudness > 0.8;
	}
	
	action drinkBeer(int quantity) {
		happiness <- happiness + 0.1 * (quantity);
		drunkness <- drunkness + 0.1;
	}
	
	action handleBeerOrderedByFriend {
		// if I am a friend of the other dancing guy
		loop i over: informs {
			string msg <- i.contents[0] as string;
			if (msg = BEER_IN_STOCK) {
				write name + " drinks";
				do drinkBeer(i.contents[1] as int);
			} else if (msg = NO_MORE_BEER) {
				happiness <- happiness - 0.1 * (i.contents[1] as int);
			}
			do end_conversation message: i contents: ["Alright."] ;
		}
	}
}

species DancingGuest parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/dancing-person.png");
	rgb myColor <- #purple;
	
	float adventurous <- rnd(0.5, 1.0) with_precision 2;
	float confident <- rnd(0.5, 1.0) with_precision 2;
	float generous <- rnd(0.5, 1.0) with_precision 2;
	
	reflex isAtBarReflex when: isAtBar() {
		do handleInteractionsAtBar;
		if (timeAtBar mod 5 = 0) {
			do startInteractions;
		}
	}
	
	action handleInteractionsAtBar {
		// handle responses for started conversations
		
		loop agree over: agrees {
			string senderType <- string(type_of(agree.sender));
			switch(senderType) {
				match ChillingGuest.name {
					do askBarForBeerForMyFriend(2, agree.sender);
				}
				match Photographer.name {
					happiness <- happiness + 0.05;
				}
				match Bar.name {
					do drinkBeer(agree.contents[1] as int);
				}
			}
			string msgContent <- agree.contents[0];
		}
		
		loop refuse over: refuses {
			string senderType <- string(type_of(refuse.sender));
			switch(senderType) {
				match ChillingGuest.name {
					happiness <- happiness - 0.1;
				}
				match Photographer.name {
					happiness <- happiness - 0.05;
				}
				match Bar.name {
					happiness <- happiness - 0.1 * (refuse.contents[1] as int);
				}
			}
			string msgContent <- refuse.contents[0];
		}
		
		loop propose over: proposes {
			string senderType <- string(type_of(propose.sender));
			switch(senderType) {
				match DancingGuest.name {
					do accept_proposal message: propose contents: ["OK! It's on me!"];
					do askBarForBeerForMyFriend(2, propose.sender);
				}
			}
			string msgContent <- propose.contents[0];
		}
		
		loop request over: requests {
			if (request.contents[0] = SECURITY_GUARD_CAUGHT_YOU) {
//				do endTimeAtBar; 
				// need to stop other reflexes, as we are already 'at the bar' so setting the currentBar to false, breaks all logic
//				goToPrison <- true;
			}
		}
		
		do handleBeerOrderedByFriend;
	}
	
	action startInteractions {
		
		list<agent> agentsAtBar <- agents_overlapping(currentBar);
		remove self from: agentsAtBar;
		if (empty(agentsAtBar) or length(agentsAtBar) = 0) {
			do aloneAtBar;
		} else {
			loop agentAtBar over: agentsAtBar {
				string agentType <- string(type_of(agentAtBar));
				switch(agentType) {
					match DancingGuest.name {
						do meetDancingGuestAtBar(agentAtBar as DancingGuest);
					}
					match ChillingGuest.name {
						do meetChillingGuestAtBar(agentAtBar as ChillingGuest);
					}
					match Photographer.name {
						do meetPhotographerAtBar(agentAtBar as Photographer);
					}
				}
			}
		}
		
		if (loudness > 0.8 and drunkness > 0.8) {
			write name + " is drunk and lound and attracts guard";
			do start_conversation to: [one_of(SecurityGuard)] protocol: "no-protocol" performative: "inform" contents: ["Catch me if you can."];
		}
	}
	
	action meetDancingGuestAtBar(DancingGuest d) {
		list<agent> initiators <- conversations collect (each.initiator);
		if (!(initiators contains d)) {
			write name + " starts drinking with " + d.name;
			do start_conversation to: [d] protocol: "fipa-propose" performative: "propose" contents: ["Let's drink"];
		}
	}
	
	action meetChillingGuestAtBar(ChillingGuest g) {
		if (generous > 0.8) {
			write name + " offers a beer to " + g;
			do start_conversation to: [g] protocol: "fipa-query" performative: "query" contents: ["Want a beer?"];
		}
	}
	
	action meetPhotographerAtBar(Photographer p) {
		if (shouldAskForPicture()) {
			write name + " asks for a picture from " + p;
			do start_conversation to: [p] protocol: "fipa-query" performative: "query" contents: ["Would you take a picture of me?"];
		}
	}
	
	action aloneAtBar {
		do askBarForBeer(1);
	}
	
	action askBarForBeerForMyFriend(int quantity, agent a) {
		write name + " and " + a.name + " are asking for a beer at bar " + currentBar.name;
		do start_conversation to: [currentBar] protocol: 'fipa-request' performative: 'request' contents: ["We would like beer.", quantity, a];
	}
	
	action askBarForBeer(int quantity) {
		write name + " is asking for a beer at bar " + currentBar.name;
		do start_conversation to: [currentBar] protocol: 'fipa-request' performative: 'request' contents: ["I would like beer.", quantity];
	}
	
	bool shouldAskForPicture {
		return confident > 0.8;
	}
}

species ChillingGuest parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/turtle.png");
	
	float cautious <- rnd(0.5, 1.0) with_precision 2;
	float nervous <- rnd(0.1, 0.3) with_precision 2;
	
	reflex isAtBarReflex when: isAtBar() {
		do handleInteractionsAtBar;
	}
	
	action handleInteractionsAtBar {
		if (!(empty(queries))) {
			loop q over: queries {
				string senderType <- string(type_of(q.sender));
				switch senderType {
					match DancingGuest.name {
						do handleDancingGuestAtBar(q);
					}
					match ChillingGuest.name {
						
					}
				}
			}
		}
		
		loop agree over: agrees {
			write name + " recieves " + agree;
			string senderType <- string(type_of(agree.sender));
			switch(senderType) {
				match Bar.name {
					happiness <- happiness + 0.1;
				}
			}
			string msgContent <- agree.contents[0];
		}
		
		do handleBeerOrderedByFriend;
	}
	
	action handleDancingGuestAtBar(message p) {
		if (acceptOfferredBeer()) {
			write "Accepting a beer from " + p.sender;
			do agree message: p contents: ["I will accept it now."] ;
		} else {
			write "Declining a beer from " + p.sender;
			do refuse message: p contents: ["I do not want a beer from a stranger"] ;
		}
	}
	
	bool acceptOfferredBeer {
		return flip(0.9);
	}
}

species Photographer parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/photographer.png");
	rgb myColor <- #pink;
	
	reflex isAtBarReflex when: isAtBar() {
		do handleInteractionsAtBar;
	}
	
	action handleInteractionsAtBar {
		if (!(empty(queries))) {
			loop q over: queries {
				string senderType <- string(type_of(q.sender));
				switch senderType {
					match DancingGuest.name {
						do handleDancingGuestAtBar(q);
					}
				}
			}
		}
	}
	
	action handleDancingGuestAtBar(message p) {
		if (acceptToTakeAPicture()) {
			write "Accepting to take a picture of " + p.sender;
			do agree message: p contents: ["I will accept it now."] ;
		} else {
			write "Declining a picture from " + p.sender;
			do refuse message: p contents: ["Leave me alone"] ;
		}
	}
	
	bool acceptToTakeAPicture {
		return flip(0.1);
	}
}

species SecurityGuard skills: [moving, fipa] {
	image_file my_icon <- image_file("../includes/data/security-guard.png");
	
	init {
		speed <- 10.0 #km/#h;
	}
	
	rgb guardColor <- #black;
	point targetPoint <- nil;
	Guest capturedGuest <- nil;
	Prison prison <- Prison closest_to(location);
	
	reflex wait when: targetPoint = nil {
		do handleLoudAndNoisyGuest;
	}
	
	// implement different behaviour when at bar and at stage
	reflex capture when: capturedGuest != nil {
		write self.name + " capturing target " + capturedGuest.name;
		do goto target: capturedGuest;
		
		if (capturedGuest.isBad() and self distance_to(capturedGuest) < 3) {
			do start_conversation to: [capturedGuest] protocol: 'fipa-request' performative: 'request' contents: [SECURITY_GUARD_CAUGHT_YOU];
			// escort to prison
			write "bringing target to prison " + capturedGuest.name;
			targetPoint <- prisonLocation;
		}
	}

	action captureBadGuest(Guest badGuest) {
		if (self != nil and badGuest != nil) {
			 write self.name + ": here at capture bad guest action of guard for guest: " + badGuest.name;
			capturedGuest <- badGuest;
		}
	}
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
		if (location = targetPoint) {
			targetPoint <- nil;
		}
	}
	
	reflex getOutOfPrison when: location = prisonLocation {
		write self.name + " in prison and should go out to capture other bad guys";
		capturedGuest <- nil;
		targetPoint <- {rnd(0.0, 100.0), rnd(0.0, 100.0)};
	}
	
	action handleLoudAndNoisyGuest {
		if (!empty(informs)) {
			message msg <- informs[0];
			write self.name + ": entering capture bad guest action: " + informs[0].sender;
			do captureBadGuest(informs[0].sender);
			do end_conversation message: msg contents: [SECURITY_GUARD_HEADING_TO_YOU];
		}
	}
	
	aspect info {
		draw cube(5) at: location color: guardColor;
		draw string(capturedGuest.name) size: 3 color: #black;
	}

	
	aspect icon {
		draw my_icon size: 4;
	}
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
	int beer <- 20 min: 0;
	
	aspect info {
		draw square(5) at: location color: #transparent border: barColor;
		draw string("Beers: " + beer) size: 3 color: barColor;
	}
	
	aspect icon {
		draw my_icon size: 5;
	}
	
	reflex reply_beer_requests when: (!empty(requests)) {
		loop r over: requests {
			agent friendAtBar <- nil;
			if ((length(list(r.contents))) > 2) {
				friendAtBar <- r.contents[2] as agent;
			}
			int requestedBeer <- r.contents[1] as int;
			
			if (beer - requestedBeer >= 0) {
				write "Agree to give you a beer.";
				do agree message: (r) contents: [BEER_IN_STOCK, requestedBeer];
				beer <- beer - (r.contents[1] as int);
				if (friendAtBar != nil) {
					do start_conversation to: [friendAtBar] protocol: 'no-protocol' performative: 'inform' contents: [BEER_IN_STOCK, requestedBeer];
				} 
			} else {
				write "No more beers.";
				do refuse message: (r) contents: [NO_MORE_BEER, requestedBeer] ;
				if (friendAtBar != nil) {
					do start_conversation to: [friendAtBar] protocol: 'no-protocol' performative: 'inform' contents: [NO_MORE_BEER, requestedBeer];
				} 
			}
		}
	}
}

species Prison {
	rgb myColor <- #grey;
	image_file my_icon <- image_file("../includes/data/prison.png");
	
	init {
		location <- prisonLocation;
	}
	
	aspect info {
		draw square(5) at: location color: myColor;
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
			species Photographer aspect: icon;
			species Prison aspect: icon;
			species SecurityGuard aspect: icon;
        }

        display info_display {
            species Guest aspect: info;
			species DancingGuest aspect: info;
			species ChillingGuest aspect: info;
			species Bar aspect: info;
			species Stage aspect: info;
			species Photographer aspect: info;
			species Prison aspect: info;
			species SecurityGuard aspect: info;
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

