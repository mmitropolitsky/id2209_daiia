/***
* Name: testfipa
* Author: Viktoriya and Milko
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model dutchauction

/* Insert your model definition here */

global {
	list genres <- ['clothes', 'CDs', 'mugs', 'bulbs'];
	list genresColors <- [#blue, #yellow, #green, #purple];
	init {
		create Guest number: 1;
		create Auctioneer number: 2;
	}
}

/**
 * Auctioneer Species
 */
species Auctioneer skills: [fipa] {
	
	float initialPrice <- rnd(280, 300);
	float currentPrice <- initialPrice;
	float minPrice <- rnd(20, 40);
	list interestedParticipants;
	int genreIndex <- rnd(0,3);
	string genre <- "CDs";//genres[genreIndex];
	rgb myColor <- genresColors[genreIndex];
	
	bool inGuestAuction <- false;
	
	aspect default {
		draw square(2) at: location color: myColor;
	}
	

	
	reflex read_interested_participants when: empty(interestedParticipants) and time mod 2 = 0 and !inGuestAuction{
		loop i over: mailbox {
			int size <-  length(list(i.contents));
			write '(Time ' + time + '): ' +  name + ' receives message with content: ' + string(i.contents);
			if (size = 2) { // it is not info about reject, but a new interested customer
				agent a <- agent(i.contents[1]);
				add a to: interestedParticipants;
			} 
		}
	}
	
	reflex send_proposal_for_discount when: (!empty(informs)) {
		loop r over: informs {
			if(r.contents[0] = "participation_auction_begin" and inGuestAuction = false) {
				inGuestAuction <- true;
				float rand <- rnd(0.0, 10.0, 0.5);
				write '(Time ' + time + '): ' +  name + 'Sending inform message to ' + r.sender + ' with value ' + rand;
				do inform message: r contents: [rand];		
			} else if (r.contents[0] = "participation_auction_win" and inGuestAuction = true) {
				write '(Time ' + time + '): ' +  name + 'Adding ' + r.sender + ' to possible participants!';
				add r.sender to: interestedParticipants;
				inGuestAuction<- false;
				do end_conversation message: r contents: ["ok"];
			} else if (r.contents[0] = "participation_auction_lose" and inGuestAuction = true) {
				do end_conversation message: r contents: ["ok :("];
				write '(Time ' + time + '): ' +  name + 'Lost contest from ' + r.sender;
				inGuestAuction<-false;
			} 
		}
	}
	
	reflex send_inform_to_participants when: empty(interestedParticipants) and time mod 2 = 0 and !inGuestAuction{
		write 'Genre of actioneer ' + name + ' is ' + genre;
		list<Guest> possibleBuyers <- Guest at_distance(100);
		if (possibleBuyers != nil and !empty(possibleBuyers)) {
			write '(Time ' + time + '): ' +  name + ' is starting an auction ';
			do start_conversation to: possibleBuyers protocol: 'fipa-contract-net' performative: 'inform' contents: ['Selling ' + genre, genre] ;
		}
	}
	

	
	reflex send_cfp_to_participants when: !empty(interestedParticipants) and time mod 2 = 0 {
		write '(Time ' + time + '): ' + name + ' sends a cfp message to potential buyers with price ' + currentPrice;
		// does the auction sell only 1 thing??
		do start_conversation to: interestedParticipants contents: ['My price is', currentPrice] performative: 'cfp' protocol: 'fipa-contract-net' ;
		currentPrice <- currentPrice - rnd(10, 30);	
	}
	
	reflex receive_refuse_messages when: !empty(refuses) and time mod 2 = 0 {
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		
		loop r over: refuses {
			write '(Time ' + time + '): ' + name + ' receives a refuse message from ' + agent(r.sender).name + ' with content ' + r.contents ;
			if (currentPrice < minPrice) {
				do start_conversation to: list(r.sender) contents: ['Ending auction due to too low price'] 
					performative: 'inform' protocol: 'fipa-contract-net';
				write '\t' + name + ' ends auction due to low price: ' + agent(r.sender).name + ' with content ' + r.contents ;
				currentPrice <- initialPrice;
				interestedParticipants <- [];
			}
		}
	}
	
	reflex receive_propose_messages when: !empty(proposes) and time mod 2 = 0 {
		list allProposes <- list(proposes);
		write '(Time ' + time + '): ' + name + ' receives proposes messages ' + allProposes;
		message proposalToAccept <- allProposes[0];
		write '(Time ' + time + '): ' + name + ' proposal to accept ' + proposalToAccept;
		do accept_proposal message: proposalToAccept contents: ['Accepting proposal ' + proposalToAccept];
		do stopGuestFromParticipatingInAuction(proposalToAccept.sender);
		write '(Time ' + time + '): buyer ' + proposalToAccept.sender + ' accepts proposal for ' + proposalToAccept.contents[0];
		write 'Number of proposes: ' + length(proposes);
		if (length(allProposes) > 0) {
			loop p over: proposes {
				do reject_proposal message: p contents: ['Rejecting proposal ' + p];
				write '(Time ' + time + '): buyer ' + p.sender + ' rejects proposal for ' + p.contents[0];
				do stopGuestFromParticipatingInAuction(p.sender);
			}
		}
		do releaseAllGuestsFromAuction;
		currentPrice <- initialPrice;
		interestedParticipants <- [];
		write '(Time ' + time + '): ' + name + ' successfully ending auction.';
	}
	
	reflex receive_reject_proposals when: !empty(reject_proposals) {
		loop r over: reject_proposals{
			write '(Time ' + time + '): ' + name + ' receives a reject_proposal message from ' + agent(r.sender).name + ' with content ' + r.contents;
			do stopGuestFromParticipatingInAuction(Guest(r.sender));
		}
	}
	
	action stopGuestFromParticipatingInAuction(Guest guest) {
		guest.isInAuction <- false;
		guest.myColor <- #red;
		loop m over: guest.mailbox {}
	}
	
	action releaseAllGuestsFromAuction {
		loop i over: interestedParticipants {
			do stopGuestFromParticipatingInAuction(i);
		}
	}
	
}

/**
 * Guest Species
 */
species Guest skills: [moving, fipa] {
	init {
		speed <- 5.0 #km/#h;
	}
	
	rgb myColor <- #red;
	float acceptablePrice <- rnd(10, 200);
	int genreIndex <- rnd(0,3);
	string interestedGenre <- "CDs";//genres[genreIndex];
	bool isInAuction <- false;
	bool isInAuctionBetweenAuctioneers <- false;
	list<message> possibleAuctioneersMessages;
	list possibleAuctioneers;
	
	reflex send_inform_to_possible_auctioneers when: !empty(possibleAuctioneersMessages) {
		if (possibleAuctioneersMessages != nil and !empty(possibleAuctioneersMessages)) {
			write '(Time ' + time + '): ' +  name + ' is starting a guest auction ';
			isInAuctionBetweenAuctioneers <- true;
			do start_conversation to: possibleAuctioneers protocol: 'no-protocol' 
				performative: 'inform' contents: ["participation_auction_begin"];
		}
	}
	
	reflex choose_auctioneer when: !empty(informs) and !empty(possibleAuctioneersMessages) and isInAuctionBetweenAuctioneers = true {
		float maxValue <- 0.0;
		write "Agrees are: " + informs;
		
		list<message> temp <- [];
		loop a over: informs {
			add a to: temp;	
		}
		
		message max <- temp with_max_of (float(each.contents[0]));
		list<message> notMax <- temp where (each != max);
		

		if (max != nil) {
			write "Sending accept message to MAX with value " + float(max.contents[0]);
			do inform message: max contents: ["participation_auction_win","you are in!"];
			isInAuctionBetweenAuctioneers <- false;
			possibleAuctioneersMessages <- [];
			do participateInAuction(Auctioneer(max.sender).myColor);
			max <- nil;
		}
		
		loop m over: notMax {
			write "Sending reject message to A with value " + float(m.contents[0]);
				do inform message: m contents: ["participation_auction_lose", "you are not in, sorry"];
		}
		
	}
	
	reflex read_inform when: !empty(informs) {// and time mod 2 = 1 {
			loop i over: informs {
				if (!self.isInAuction) {
					write '(Time ' + time + '): ' + name + ' receives message with content: ' + (string(i.contents)) + " from " + agent(i.sender).name;
					
					if (i.contents[1] = interestedGenre) {
						add i to: possibleAuctioneersMessages;	
						add i.sender to: possibleAuctioneers;
					} else {
						do end_conversation message: i contents: ['Not interested in offer from ' + agent(i.sender).name];
					}
					
				}
		}
	}
	
	reflex receive_cfp_from_auctioneer when: !empty(cfps) and time mod 2 = 1 and isInAuction{
		message proposalFromAuctioneer <- cfps[0];
		float priceFromAuctioneer <- list(proposalFromAuctioneer.contents)[1] as float;
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' 
			+ agent(proposalFromAuctioneer.sender).name;
			
		write 'Willing to pay ' + acceptablePrice;
		// what should be the condition to understand an auction??
		if (priceFromAuctioneer > acceptablePrice) {
			write '(Time ' + time + '): ' + ' buyer ' + name + ' rejects offer';
			do refuse message: proposalFromAuctioneer contents: ['Rejecting offer'];
		} else {
			write '(Time ' + time + '): ' + ' buyer ' + name + ' proposes price ' + acceptablePrice;
			do propose message: proposalFromAuctioneer contents: [priceFromAuctioneer];
		}
	}
	
	reflex dance when: !isInAuction {
		do wander;
	}
	
	action participateInAuction(rgb auctioneerColor) {
		isInAuction <- true;
		myColor <- auctioneerColor;
	}
	
	aspect default {
		draw sphere(1) at: location color: myColor;
	}
}

experiment name type: gui {
	output {
		display displayFest type: opengl {
			species Guest;
			species Auctioneer;
		}	
	}
}

