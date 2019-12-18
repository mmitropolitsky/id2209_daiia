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
	
	string ASK_MERCHANT_FOR_OFFER <- "I would like to buy something.";
	string MERCHANT_MAKES_AN_OFFER <- "You can buy merchandise now.";
	string MERCHANT_IS_NOT_WORKING <- "Sorry, I am not working.";
	string BUY_MERCHANDISE <- "I will buy this.";
	string MERCHANT_NOT_TRUSTWORTHY <- "You are not trustworthy.";
	float MERCHANT_WORKING_AT_BAR <- 0.2;

	int numOfGuests -> {length (DancingGuest) + length(ChillingGuest) + length(Photographer)};
    int amusedGuests update: DancingGuest count (each.happiness > 0.8) 
    						+ ChillingGuest count (each.happiness > 0.8)
    						+ Photographer count (each.happiness > 0.8);
    int drunkPeople update: DancingGuest count (each.drunkness > 0.8) 
    						+ ChillingGuest count (each.drunkness > 0.8)
    						+ Photographer count (each.drunkness > 0.8);
	
	int numberOfGuests <- 10;
	int barsNum <- 5;
	int stageNum <- 5;
	int currentBarsNum -> {length(Bar)};
	
	// print debug logs or not
	bool debug <- true;
	
	point prisonLocation <- {90.0, 90.0};
	
	list<string> musicTypes <- ["rock", "pop", "jazz"];

	init {
		create DancingGuest number: numberOfGuests;
		create ChillingGuest number: numberOfGuests;
		create Photographer number: numberOfGuests;
		create SecurityGuard number: numberOfGuests;
		create Merchant number: numberOfGuests;
		create Bar number: barsNum;
		create Prison number: 1;
		create Stage number: stageNum;
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
	bool prefersCompany <- flip(0.5);
	
	int size <- 1;
	
	float goToBar <- 0.2 with_precision 2;
	float goToStage <- 0.2 with_precision 2;
	bool goToPrison <- false;
	
	Stage currentStage <- nil;
	Bar currentBar <- nil;
	point randomPoint <- nil;
	
	int TIME_AT_BAR <- 30;
	int TIME_AT_STAGE <- 100;
	int TIME_AT_PRISON <- 10;
	
	int timeAtBar <- TIME_AT_BAR update: isAtBar() ? timeAtBar - 1 : timeAtBar min: 0;
	int timeAtStage <- TIME_AT_STAGE update: isAtStage() ? timeAtStage - 1 : timeAtStage min: 0;
	int timeAtPrison <- TIME_AT_PRISON update: isAtPrison() ? timeAtPrison - 1 : timeAtPrison min: 0;
	
	aspect info {
		draw sphere(size) at: location color: myColor border: #black;
		draw string(happiness with_precision 2) size: 3 color: #black;
	}
	
	aspect icon {
		draw my_icon size: 2 * size;
	}
	
	reflex defaultBehaviour when: currentStage = nil and currentBar = nil {
		do wander;
		if (randomPoint != nil) {
			do goto target: randomPoint;
			if (self.location = randomPoint) {
				randomPoint <- nil;
			}
		} else if (goToPrison) {
			do goto target: one_of(Prison);
		} else if (flip(goToStage)) {
			currentStage <- one_of(Stage);
		} else if (flip(goToBar)) {
			currentBar <- one_of(Bar);
		}
	}
	
	// Bar related
	reflex goToBar when: currentBar != nil {
		do goto target: currentBar;
	}
	
	reflex isAtBar when: isAtBar() {
		if (timeAtBar = 0) {
			do endTimeAtBar;
		}
	}
	
	action endTimeAtBar {
		timeAtBar <- TIME_AT_BAR;
		currentBar <- nil;
		randomPoint <- { rnd(0.0, 100.0), rnd(0.0, 100.0) };
	}
	
	bool isAtBar {
		return currentBar != nil and location = currentBar.location;
	}
	
	// Stage related
	reflex goToStage when: currentStage != nil {
		do goto target: currentStage;
	}
	
	reflex isAtStage when: isAtStage() {
		if (timeAtStage = 0) {
			do endTimeAtStage;
		}
	}
	
	action endTimeAtStage {
		timeAtStage <- TIME_AT_STAGE;
		currentStage <- nil;
		randomPoint <- { rnd(0.0, 100.0), rnd(0.0, 100.0) };
	}
	
	bool isAtStage {
		return currentStage != nil and location = currentStage.location;
	}
	
	
	// Prison related
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
	
	// after a friend orders a beer for me, the bar sends an inform message whether there is more beer left or not
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
	
	bool hasApproachedMerchant <- false;

	reflex isAtBarReflex when: isAtBar() {
		do handleInteractions;
		if (timeAtBar mod 30 = 0) {
			hasApproachedMerchant <- false;
		}
		if (timeAtBar mod 5 = 0) {
			do startInteractionsAtBar;
		}
	}
	
	reflex isAtStageReflex when: isAtStage() {
		do handleInteractions;
		if (timeAtStage mod 10 = 0) {
			do startInteractionsAtStage;
		}
	}
	
	action handleInteractions {
		// handle responses for started conversations
		//at bar receiving positive response from either ChillGuest or Photographer or Bar
		loop agree over: agrees {
			string senderType <- string(type_of(agree.sender));
			switch(senderType) {
				match ChillingGuest.name {
					if (agree.contents[0] = "BAR" and agree.contents[1] = currentBar) {
						do askBarForBeerForMyFriend(2, agree.sender);
					}
				}
				match Photographer.name {
					if (agree.contents[0] = "BAR" and agree.contents[1] = currentBar) {
						happiness <- happiness + 0.05;
					}
				}
				match Bar.name {
					do drinkBeer(agree.contents[1] as int);
				}
			}
			string msgContent <- agree.contents[0];
		}
		
		//at bar receiving negative response from either ChillGuest or Photographer or Bar
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
				//after approaching the Merchant for an offer, if he is not working, we receive a refuse 
				match Merchant.name {
					if (refuse.contents[0] = "BAR" and refuse.contents[1] = currentBar) {
						write "Time[" + time + "]: " + name + " receives a refuse from merchant " + refuse.sender;
						happiness <- happiness - 0.05;
					}
				}
			}
			string msgContent <- refuse.contents[0];
		}
		
		//at bar meeting another dancing guest that invites us to drink with them;
		//current dancing guest is asking bar for beers for both current and the friend that invited us to drink
		loop propose over: proposes {
			string senderType <- string(type_of(propose.sender));
			switch(senderType) {
				match DancingGuest.name {
					write name + " type of sender is DG";
					if (propose.contents[0] = "BAR" and propose.contents[1] = currentBar) {
						write name + " locatino of sender is current bar " + currentBar.name;
						do accept_proposal message: propose contents: ["OK! It's on me!"];
						do askBarForBeerForMyFriend(2, propose.sender);	
					} else if (propose.contents[0] = "STAGE" and propose.contents[1] = currentStage) {
						string msg <- "Yes, let's dance!";
						do accept_proposal message: propose contents: [msg];
						write name + " is dancing now at stage " + currentStage.name + " with " + propose.sender + ". Sends a response: " + msg;
						// TODO maybe add countdown?
						do danceAtStage;
					}
				}
				//after approaching the Merchant for an offer, if he is working, he makes a proposal to the dancing guest 
				match Merchant.name {
					if (propose.contents[0] = "BAR" and propose.contents[1] = currentBar) {
						write "Time[" + time + "]: " + name + " receives a proposal from merchant " + propose.sender;
						if (shouldBuyFromMerchantAtBar(Merchant(propose.sender))) {
							write "Time[" + time + "]: " + name + " is buying from " + propose.sender;
							do accept_proposal message: propose contents: ["BAR", currentBar, BUY_MERCHANDISE];
							happiness <- happiness + 0.1;
						} else {
							write "Time[" + time + "]: " + name + " is not buying from " + propose.sender;
							do reject_proposal message: propose contents: ["BAR", currentBar, MERCHANT_NOT_TRUSTWORTHY];
						}
					}
				}
			}
			string msgContent <- propose.contents[0];
		}
		
		// at bar, security guard reaches us and our happiness goes down
		loop request over: requests {
			if (request.contents[0] = SECURITY_GUARD_CAUGHT_YOU) {
				happiness <- happiness - 0.3;
			}
		}
		
		do handleBeerOrderedByFriend;
	}

	action handleInteractionsAtStage {
		
		
	}

	action startInteractionsAtBar {
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
					match Merchant.name {
						do meetMerchantAtBar(agentAtBar as Merchant);
					}
				}
			}
		}

		if (loudness > 0.8 and drunkness > 0.8) {
			write name + " is drunk and lound and attracts guard";
			SecurityGuard securityGuard <- one_of(SecurityGuard);
			if (securityGuard != nil) {
				do start_conversation to: [securityGuard] 
				protocol: "no-protocol" 
				performative: "inform" 
				contents: ["BAR", currentBar, "Catch me if you can."];
			}
		}
	}

	action startInteractionsAtStage {
		list<agent> agentsAtStage <- agents_overlapping(currentStage);
		remove self from: agentsAtStage;
		if (empty(agentsAtStage) or length(agentsAtStage) = 0) {
			do aloneAtStage;
		} else {
			loop agentAtStage over: agentsAtStage {
				string agentType <- string(type_of(agentAtStage));
				switch(agentType) {
					match DancingGuest.name {
						do meetDancingGuestAtStage(agentAtStage as DancingGuest);
						write name + " is dancing now at stage " + currentStage.name + " with " + agentAtStage.name;
						do danceAtStage;
					}
					match ChillingGuest.name {
						write "DG meetings CG at Stage is NOT YET IMPLEMENTED!";
					}
				}
			}
		}
	}
	
	
	/*
	 * MEET DANCING GUEST
	 */
	 // At a bar
	action meetDancingGuestAtBar(DancingGuest d) {
		list<agent> initiators <- conversations collect (each.initiator);
		if (!(initiators contains d)) {
			string msg <- "Let's drink";
			write name + " starts drinking with " + d.name + " and sends message " + msg;
			do start_conversation to: [d] protocol: "fipa-propose" performative: "propose" 
				contents: ["BAR", currentBar, msg];
		}
	}
	
	// At a stage
	action meetDancingGuestAtStage(DancingGuest d) {
		list<agent> initiators <- conversations collect (each.initiator);
		if (!(initiators contains d)) {
			string msg <- "Let's dance together!";
			write name + " starts dancing with " + d.name + " at stage " + currentStage.name + " and sends message " + msg;
			do start_conversation to: [d] protocol: "fipa-propose" performative: "propose" 
				contents: ["STAGE", currentStage, msg];
		}
	}
	
	
	/*
	 * MEET CHILLING GUEST
	 */
	 // At a bar
	action meetChillingGuestAtBar(ChillingGuest g) {
		if (generous > 0.8) {
			write "Time [" + time + "]: " + name + " offers a beer to " + g + " at location " + currentBar;
			do start_conversation to: [g] protocol: "fipa-query" performative: "query" 
				contents: ["BAR", currentBar, "Want a beer?"];
		}
	}
	
	// At a stage
	action meetChillingGuestAtStage(ChillingGuest g) {
		// TODO
	}
	
	// MEET PHOTOGRAPHER
	
	action meetPhotographerAtBar(Photographer p) {
		if (shouldAskForPicture()) {
			write name + " asks for a picture from " + p;
			do start_conversation to: [p] protocol: "fipa-query" performative: "query" 
				contents: ["BAR", currentBar, "Would you take a picture of me?"];
		}
	}
	
	action meetPhotographerAtStage(Photographer p) {
		// TODO
	}

	// MEET MERCHANT

	action meetMerchantAtBar(Merchant m) {
		if (shouldApproachMerchantAtBar()) {
			write "Time[" + time + "]: " + name + " approaches merchant " + m;
			do start_conversation to: list(m) protocol: 'fipa-contract-net' performative: 'cfp' contents: ["BAR", currentBar, ASK_MERCHANT_FOR_OFFER];
           	hasApproachedMerchant <- true;
   		}
   }
   
   action meetMerchantAtStage(Merchant m) {
		// TODO
   }
	
	action aloneAtBar {
		do askBarForBeer(1);
	}
	
	action aloneAtStage {
		// write what the agent is doing
		write name + " is dancing alone at stage" + currentStage.name;
		
		// decrease loudness
		loudness <- loudness - 0.01;
		
		// increase/decrease happiness based on prefers to be alone or not
		float newHappiness <- prefersCompany ? happiness + 0.01 : happiness - 0.01;
		
		if (debug) {
			write name + " happiness was: " + happiness + ", new happiness is: " 
				+ newHappiness + ". Loudness is now: " + loudness + " (was " + (loudness + 0.01) + ")."; 	
		} 
		
		happiness <- newHappiness;
	}
	
	/*
	 * Increase happiness when dancing!
	 */
	action danceAtStage {
		float happinessIncrement <- prefersCompany ? 0.2 : 0.1;
		happiness <- happiness + happinessIncrement;
		
		loudness <- loudness + 0.01;
		
		if (debug) {
			write name + " happiness is increased by " 
				+ happinessIncrement + " and is now " 
				+ happiness + " (was" + (happiness - happinessIncrement) + "). Loudness is increased by 0.01 to " + loudness;
		}
		
	}
	
	action askBarForBeerForMyFriend(int quantity, agent a) {
		write name + " and " + a.name + " are asking for a beer at bar " + currentBar.name;
		do start_conversation to: [currentBar] protocol: 'fipa-request' performative: 'request' contents: ["We would like beer.", quantity, a];
	}
	
	action askBarForBeer(int quantity) {
		write name + " is asking for a beer at bar " + currentBar.name;
		do start_conversation to: [currentBar] protocol: 'fipa-request' performative: 'request' contents: ["I would like beer.", quantity];
	}
	
	/*
	 * RULES
	 */
	
	bool shouldAskForPicture {
		return confident > 0.8;
	}
	
	bool shouldApproachMerchantAtBar {
		return confident > 0.5 and !hasApproachedMerchant;
	}
	
	bool shouldBuyFromMerchantAtBar(Merchant m) {
		return m.trustworthy > 0.3;
	}
}

species ChillingGuest parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/turtle.png");
	
	float cautious <- rnd(0.5, 1.0) with_precision 2;
	float nervous <- rnd(0.1, 0.3) with_precision 2;
	float positive <- rnd(0.1, 0.7) with_precision 2;
	
	reflex isAtBarReflex when: isAtBar() {
		do handleInteractions;
	}
	
	reflex isAtBarToStartInteractionsReflex when: isAtBar() and timeAtBar mod 5 = 0 {
		do startInteractionsAtBar;
	}
	
	action startInteractionsAtBar {
		write name + "start interactions at bar" + time;
		list<agent> agentsAtBar <- agents_overlapping(currentBar);
		remove self from: agentsAtBar;
		if (empty(agentsAtBar) or length(agentsAtBar) = 0) {
			do aloneAtBar;
		} else {
			loop agentAtBar over: agentsAtBar {
				string agentType <- string(type_of(agentAtBar));
				switch(agentType) {
					match DancingGuest.name {
						// TODO
//						do meetDancingGuestAtBar(agentAtBar as DancingGuest);
					}
					match ChillingGuest.name {
						// TODO
//						do meetChillingGuestAtBar(agentAtBar as ChillingGuest);
					}
					match Photographer.name {
						// TODO
//						do meetPhotographerAtBar(agentAtBar as Photographer);
					}
				}
			}
		}	
	}
	
	
	action handleInteractions {
		loop q over: queries {
			string senderType <- string(type_of(q.sender));
			switch senderType {
				match DancingGuest.name {
					if (q.contents[0] = "BAR" and q.contents[1] = currentBar) {
						do handleDancingGuestAtBar(q);
					} else if(q.contents[0] = "STAGE" and q.contents[1] = currentStage) {
						// TODO not implemented
					}
				}
				match ChillingGuest.name {
					
				}
			}
		}
		
		loop agree over: agrees {
			write name + " recieves " + agree;
			string senderType <- string(type_of(agree.sender));
			switch(senderType) {
				match Bar.name {
					// if we are too drunk, happiness goes down...
					drunkness <- drunkness + 0.1;
					if (drunkness < 0.8) {
						happiness <- happiness + 0.1;	
					} else {
						happiness <- happiness - 0.1;
					}
				}
			}
			string msgContent <- agree.contents[0];
		}
		
		do handleBeerOrderedByFriend;
	}
	
	/*
	 * ACTIONS
	 */
	action aloneAtBar {
		if (shouldOrderABeerWhenAlone()) {
			do askBarForBeer(1);
		} else {
			write "[Time: " + time + "] " + name + " is just chilling at bar " + currentBar.name;
		}
	}
	
	action handleDancingGuestAtBar(message p) {
		message m <- p;
		if (shouldGoAwayFromBar(m.sender as DancingGuest)) {
			do refuse message: m contents: ["BAR", currentBar, "I do not want a beer from a you!"] ;
			do endTimeAtBar;
			write "[Time: " + time + "] " + name + " leaves bar because of the annoying Dancing guest " + m.sender;
			happiness <- happiness - 0.1;
		} else {
			do handleBeerProposalFromDancingGuestAtBar(m);	
		}
	}
	
	action handleBeerProposalFromDancingGuestAtBar(message p) {
		if (acceptOfferredBeer()) {
			write "Time[" + time + "]: Accepting a beer from " + p.sender;
			do agree message: p contents: ["BAR", currentBar, "I will accept it now.", cycle] ;
			happiness <- happiness + 0.1;
		} else {
			write "Declining a beer from " + p.sender;
			do refuse message: p contents: ["BAR", currentBar, "I do not want a beer from a stranger"] ;
			happiness <- happiness - 0.1;
		}
	}

	action askBarForBeer(int quantity) {
		write name + " is asking for a beer at bar " + currentBar.name;
		do start_conversation to: [currentBar] protocol: 'fipa-request' performative: 'request' contents: ["I would like beer.", quantity];
	}


	/*
	 * RULES
	 */
	bool shouldGoAwayFromBar(DancingGuest dg) {
		write name + "in should go away from bar";
		return dg.loudness > 0.8 and positive < 0.7;
	} 
	 	
	bool acceptOfferredBeer {
		return cautious < 0.7 and nervous < 0.8;
	}
	
	bool shouldOrderABeerWhenAlone {
		bool shouldOrder <- (nervous > 0.5 or positive > 0.5) and currentBar != nil;
		return shouldOrder;
	}
	
}

species Photographer parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/photographer.png");
	rgb myColor <- #pink;
	
	reflex isAtBarReflex when: isAtBar() {
		do handleInteractions;
	}
	
	action handleInteractions {
		if (!(empty(queries))) {
			loop q over: queries {
				string senderType <- string(type_of(q.sender));
				switch senderType {
					match DancingGuest.name {
						if (q.contents[0] = "BAR" and q.contents[1] = currentBar) {
							do handleDancingGuestAtBar(q);
						} else if(q.contents[0] = "STAGE" and q.contents[1] = currentStage) {
							// TODO not implemented
						}
					}
				}
			}
		}
	}
	
	action handleDancingGuestAtBar(message p) {
		if (acceptToTakeAPicture()) {
			write "Accepting to take a picture of " + p.sender;
			do agree message: p contents: ["BAR", currentBar, "I will accept it now."] ;
		} else {
			write "Declining a picture from " + p.sender;
			do refuse message: p contents: ["BAR", currentBar, "Leave me alone"] ;
		}
	}
	
	bool acceptToTakeAPicture {
		return flip(0.1);
	}
}

species Merchant parent: Guest {
	
	image_file my_icon <- image_file("../includes/data/merchant.jpg");
	rgb myColor <- #aquamarine;
	
	float trustworthy <- rnd(0.0, 1.0) with_precision 2;
	float convincing <- rnd(0.0, 1.0) with_precision 2;
	float promoting <- rnd(0.0, 1.0) with_precision 2;
	
	reflex isAtBarReflex when: isAtBar() {
		do handleInteractionsAtBar;
	}
	
	action handleInteractionsAtBar {
		loop cfp over: cfps {
			string senderType <- string(type_of(cfp.sender));
	        switch(senderType) {
				match DancingGuest.name {
	            	do handleDancingGuestAtBar(cfp);
	            }
	       	}
	    }
		
		loop reject over: reject_proposals {
			string senderType <- string(type_of(reject.sender));
			switch(senderType) {
				match DancingGuest.name {
					if (reject.contents[0] = "BAR" and reject.contents[1] = currentBar and reject.contents[2] = MERCHANT_NOT_TRUSTWORTHY) {
							write "Time[" + time + "]: " + name + "'s offer is rejected by " + reject.sender;
							happiness <- happiness - 0.1;
					}
				}
			}
		}
	
		loop accept over: accept_proposals {
			string senderType <- string(type_of(accept.sender));
				switch(senderType) {
					match DancingGuest.name {
						if (accept.contents[0] = "BAR" and accept.contents[1] = currentBar and accept.contents[2] = BUY_MERCHANDISE) {
							write "Time[" + time + "]: " + name + "'s offer is accepted by " + accept.sender;
							happiness <- happiness + 0.1;	
						}
				}
			}
		}
	}
	
	action handleDancingGuestAtBar(message cfp) {
		if (cfp.contents[0] = "BAR" and cfp.contents[1] = currentBar and cfp.contents[2] = ASK_MERCHANT_FOR_OFFER) {
        	bool isWorking <- flip(MERCHANT_WORKING_AT_BAR);
            if (isWorking) {
            	write "Time[" + time + "]: " + name + " makes a proposal " + cfp.sender;
                do propose message: cfp contents: ["BAR", currentBar, MERCHANT_MAKES_AN_OFFER];
            } else {
            	write "Time[" + time + "]: " + name + " refuses offer from " + cfp.sender;
                do refuse message: cfp contents: ["BAR", currentBar, MERCHANT_IS_NOT_WORKING];
            }
        }
	}
}

species SecurityGuard skills: [moving, fipa] {
	image_file my_icon <- image_file("../includes/data/security-guard.png");
	
	init {
		speed <- 10.0 #km/#h;
	}
	
	rgb guardColor <- #black;
	Guest capturedGuest <- nil;
	Prison prison <- Prison closest_to(location);
	
	reflex wait when: capturedGuest = nil {
		do wander;
		do handleLoudAndNoisyGuest;
	}
	
	reflex capture when: capturedGuest != nil {
		write self.name + " capturing target " + capturedGuest.name;
		do goto target: capturedGuest;
		
		if (capturedGuest.isBad() and self distance_to(capturedGuest) < 3) {
			do start_conversation to: [capturedGuest] protocol: 'fipa-request' performative: 'request' contents: [SECURITY_GUARD_CAUGHT_YOU];
			capturedGuest <- nil;
		}
	}

	action captureBadGuest(Guest badGuest) {
		if (self != nil and badGuest != nil) {
			 write self.name + ": here at capture bad guest action of guard for guest: " + badGuest.name;
			capturedGuest <- badGuest;
		}
	}
	
	action handleLoudAndNoisyGuest {
		if (!empty(informs)) {
			message msg <- informs[0];
			write self.name + ": entering capture bad guest action: " + informs[0].sender;
			capturedGuest <- informs[0].sender;
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
			species Merchant aspect: icon;
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
			species Merchant aspect: info;
        }
		
		display Happiness_information refresh: every(5#cycles) {
			chart "Happiness and drunkness correlation" type: series size: {1,0.5} position: {0, 0} {
                data "number_of_amused_guests" value: amusedGuests color: #blue;
                data "number_of_drunk_guests" value: drunkPeople color: #red;
            }
            chart "DancingGuest Happiness Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0.5} {
                data "[0;0.25]" value: DancingGuest count (each.happiness <= 0.25) color:#blue;
                data "[0.25;0.5]" value: DancingGuest count ((each.happiness > 0.25) and (each.happiness <= 0.5)) color:#blue;
                data "[0.5;0.75]" value: DancingGuest count ((each.happiness > 0.5) and (each.happiness <= 0.75)) color:#blue;
                data "[0.75;1]" value: DancingGuest count (each.happiness > 0.75) color:#blue;
            }
		}
		monitor "Number of amused guests: " value: amusedGuests;
    	monitor "All guests: " value: numOfGuests;
	}
	
	
}

