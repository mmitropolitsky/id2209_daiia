/***
* Name: testfipa
* Author: Viktoriya and Milko
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model dutchauction

/* Insert your model definition here */
global {

	map<string, list> amountWonFromAuction; 
	list auctions <- ['Dutch', 'English'];
	string DUTCH_AUCTION_TYPE <- 'Dutch';
	string ENGLISH_AUCTION_TYPE <- 'English';
	string VICKREY_BID_AUCTION_TYPE <- 'Vickrey';
	string AUCTION_ENDED <- 'auctionEnded';
	init {
		create Guest number: 20;
		create Auctioneer number: 2;
		create EnglishAuctioneer number: 2;
		create VickreyAuctioneer number: 2;
	}
}

/**
 * Dutch Auctioneer Species
 */
species Auctioneer skills: [fipa] {
	
	rgb myColor <- #blue;
	float initialPrice <- 350;
	float currentPrice <- initialPrice;
	float minPrice <- 50;
	list interestedParticipants;
	list<float> valueGained;
	
	aspect default {
		draw square(2) at: location color: myColor;
	}
	
	//valid for Dutch and English
	reflex read_interested_participants when: empty(interestedParticipants) and time mod 2 = 0 {
		loop i over: mailbox {
			int size <-  length(list(i.contents));
			write '(Time ' + time + '): ' +  name + ' receives message with content: ' + string(i.contents);
			if (size = 2) { // it is not info about reject, but a new interested customer
				agent a <- agent(i.contents[1]);
				add a to: interestedParticipants;
			} 
		}
	}
	
	reflex send_inform_to_participants when: empty(interestedParticipants) and time mod 2 = 0 {
		list<Guest> possibleBuyers <- Guest at_distance(15);
		if (possibleBuyers != nil and !empty(possibleBuyers)) {
			write '(Time ' + time + '): ' +  name + ' is starting a Dutch auction ';
			do start_conversation to: possibleBuyers protocol: 'fipa-contract-net' performative: 'inform' contents: ['Selling clothes', DUTCH_AUCTION_TYPE] ;
		}
	}
	
	// only for Dutch
	reflex send_cfp_to_participants_dutch when: !empty(interestedParticipants) and time mod 2 = 0 {
		write '(Time ' + time + '): ' + name + ' sends a cfp message to potential buyers with price ' + currentPrice;
		// does the auction sell only 1 thing??
		do start_conversation to: interestedParticipants contents: ['My price is', currentPrice, DUTCH_AUCTION_TYPE] performative: 'cfp' protocol: 'fipa-contract-net' ;
		currentPrice <- currentPrice - rnd(10, 50);	
	}
	
	// only for Dutch
	reflex receive_refuse_messages_dutch when: !empty(refuses) and time mod 2 = 0 {
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
	
	// only for Dutch
	reflex receive_propose_messages_dutch when: !empty(proposes) and time mod 2 = 0 {
		list allProposes <- list(proposes);
		write '(Time ' + time + '): ' + name + ' receives proposes messages ' + allProposes;
		message proposalToAccept <- allProposes[0];
		write '(Time ' + time + '): ' + name + ' proposal to accept ' + proposalToAccept;
		do accept_proposal message: proposalToAccept contents: ['Accepting proposal ' + proposalToAccept];
		do stopGuestFromParticipatingInAuction(proposalToAccept.sender);
		
		add proposalToAccept.contents[0] as float to: valueGained;
		add proposalToAccept.contents[0] as float to: Guest(proposalToAccept.sender).englishAuctionsParticipated;
		
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
		
		write name + ' gained value from Dutch auction for ' + length(valueGained) + ' auctions: ' + sum(valueGained);
		write Guest(proposalToAccept.sender).name + ' paid in ' + length(valueGained) + ' Dutch auctions: ' + sum(valueGained);
	}
	
	action stopGuestFromParticipatingInAuction(Guest guest) {
		guest.isInAuction <- false;
		guest.myColor <- #red;
	}
	
	action releaseAllGuestsFromAuction {
		loop i over: interestedParticipants {
			do stopGuestFromParticipatingInAuction(i);
		}
	}
}

/**
 * English Auctioneer Species
 */
species EnglishAuctioneer skills: [fipa] {
	
	rgb myColor <- #purple;
	float minPrice <- 50;
	float currentPrice <- minPrice;
	float acceptablePrice <- 350;
	list interestedParticipants;
	message highestBidMessage;
	list<float> valueGained;
	
	aspect default {
		draw square(2) at: location color: myColor;
	}
	
	//valid for Dutch and English
	reflex read_interested_participants when: empty(interestedParticipants) and time mod 2 = 0 {
		loop i over: mailbox {
			int size <-  length(list(i.contents));
			write '(Time ' + time + '): ' +  name + ' receives message with content: ' + string(i.contents);
			if (size = 2) { // it is not info about reject, but a new interested customer
				agent a <- agent(i.contents[1]);
				add a to: interestedParticipants;
			} 
		}
	}
	
	// only for English
	reflex receive_refuse_messages_english when: !empty(refuses) and time mod 2 = 0 {
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		loop r over: refuses {
			write '(Time ' + time + '): ' + name + ' receives a refuse message from ' + agent(r.sender).name + ' with content ' + r.contents;
			remove r.sender from: interestedParticipants;
			do stopGuestFromParticipatingInAuction(r.sender);
		}
		if (empty(proposes)) {
			do endAuction;
		}
	}
	
	// only for English
	reflex receive_propose_messages_english when: !empty(proposes) and time mod 2 = 0 {
		list allProposes <- list(proposes);
		write '(Time ' + time + '): ' + name + ' receives proposes messages ' + allProposes;
		message highestBid <- allProposes with_max_of(each.contents[0] as float);
		self.highestBidMessage <- highestBid;
		write '(Time ' + time + '): ' + name + ' highest bid is ' + highestBid;
		currentPrice <- highestBid.contents[0] as float;
		if (currentPrice >= acceptablePrice) {
			write '(Time ' + time + '): ' + name + ' accepts highest bid ' + highestBid;
			do accept_proposal message: highestBid contents: ['Accepting proposal ' + highestBid];
			
			add highestBid.contents[0] as float to: valueGained;
			add highestBid.contents[0] as float to: Guest(highestBid.sender).englishAuctionsParticipated;
			
			write '(Time ' + time + '): ' + name + ' asks ' + highestBid.sender + ' to pay bid.';
			do start_conversation to: [highestBid.sender] protocol: 'fipa-request' performative: 'request' contents: ['Please send me money'] ;
			
			remove highestBid.sender from: interestedParticipants;
			loop i over: interestedParticipants {
				do start_conversation to: interestedParticipants protocol: 'fipa-contract-net' 
					performative: 'inform' contents: ['Auction ended. Items sold to ' + highestBid.sender, AUCTION_ENDED] ;
			}
			
			write name + ' gained value from English auction for ' + length(valueGained) + ' auctions: ' + sum(valueGained);
			write Guest(highestBid.sender).name + ' paid in ' + length(valueGained) + ' English auctions: ' + sum(valueGained);
		}
	}
	
	reflex read_agree_message when: !(empty(agrees)) {
		write '(Time ' + time + '): ' + name + ' read agree messages';
		loop a over: agrees {
			write 'agree message with content: ' + string(a.contents);
		}
		do releaseAllGuestsFromAuction;
		do stopGuestFromParticipatingInAuction(highestBidMessage.sender);
		do endAuction;
	}
	
	action releaseAllGuestsFromAuction {
		loop i over: interestedParticipants {
			do stopGuestFromParticipatingInAuction(i);
		}
	}
	
	action stopGuestFromParticipatingInAuction(Guest guest) {
		guest.isInAuction <- false;
		guest.myColor <- #red;
	}
	
	action endAuction {
		currentPrice <- minPrice;
		interestedParticipants <- [];
	}
	
	reflex send_inform_to_participants when: empty(interestedParticipants) and time mod 2 = 0 {
		list<Guest> possibleBuyers <- Guest at_distance(15);
		if (possibleBuyers != nil and !empty(possibleBuyers)) {
			write '(Time ' + time + '): ' +  name + ' is starting an English auction ';
			do start_conversation to: possibleBuyers protocol: 'fipa-contract-net' performative: 'inform' contents: ['Selling clothes', ENGLISH_AUCTION_TYPE] ;
		}
	}
	
	// only for English
	reflex send_cfp_to_participants_english when: !empty(interestedParticipants) and empty(proposes) and time mod 2 = 0 {
		write '(Time ' + time + '): ' + name + ' sends a cfp message to ' + interestedParticipants + ' with price ' + currentPrice;
		// does the auction sell only 1 thing??
		do start_conversation to: interestedParticipants contents: ['My price is', currentPrice, ENGLISH_AUCTION_TYPE] performative: 'cfp' protocol: 'fipa-contract-net' ;
	}
}

species VickreyAuctioneer skills: [fipa] {
	
	rgb myColor <- #pink;
	
	aspect default {
		draw square(2) at: location color: myColor;
	}
	
	list interestedParticipants;
	list<float> valueGained;
	
	//valid for Dutch and English
	reflex read_interested_participants when: empty(interestedParticipants) and time mod 2 = 0 {
		loop i over: mailbox {
			int size <-  length(list(i.contents));
			write '(Time ' + time + '): ' +  name + ' receives message with content: ' + string(i.contents);
			if (size = 2) { // it is not info about reject, but a new interested customer
				agent a <- agent(i.contents[1]);
				add a to: interestedParticipants;
			} 
		}
	}
	
	reflex send_inform_to_participants when: empty(interestedParticipants) and time mod 2 = 0 {
		list<Guest> possibleBuyers <- Guest at_distance(15);
		if (possibleBuyers != nil and !empty(possibleBuyers)) {
			write '(Time ' + time + '): ' +  name + ' is starting a Vickrey auction ';
			do start_conversation to: possibleBuyers protocol: 'fipa-contract-net' performative: 'inform' contents: ['Selling clothes', VICKREY_BID_AUCTION_TYPE] ;
		}
	}
	
	// only for Vickrey
	reflex send_cfp_to_participants_english when: !empty(interestedParticipants) and empty(proposes) and time mod 2 = 0 {
		write '(Time ' + time + '): ' + name + ' sends a cfp message to ' + interestedParticipants + ' with price ' + 0;
		do start_conversation to: interestedParticipants contents: ['My price is', 0, VICKREY_BID_AUCTION_TYPE] performative: 'cfp' protocol: 'fipa-contract-net' ;
	}
	
	reflex receive_propose_messages_vickery when: !empty(proposes) and time mod 2 = 0 {
		list allProposes <- list(proposes);
		list<message> tail <- [];
		write '(Time ' + time + '): ' + name + ' receives proposes messages ' + allProposes;
		message highestBid <- allProposes with_max_of(each.contents[0] as float);
		
		float secondHighestBidValue <- 0.0;
		if (length(allProposes) > 1) {
			list tail <- allProposes where (each != highestBid);
			write 'Tail ' + tail;
			message secondHighestBid <- tail with_max_of(each.contents[0] as float);
			write 'Second highest bid ' + secondHighestBid;
			secondHighestBidValue <- secondHighestBid.contents[0];
		} else {
			secondHighestBidValue <- highestBid.contents[0];
		}
		write 'HIghest bid ' + highestBid;
		write 'Second highest bid ' + secondHighestBidValue;
		add secondHighestBidValue to: valueGained;
		add secondHighestBidValue to: Guest(highestBid.sender).vickreyAuctionsParticipated;
		
		write '(Time ' + time + '): ' + name + ' accepts proposal from ' + Guest(highestBid.sender).name + ' with price ' + secondHighestBidValue;
		do accept_proposal message: highestBid contents: ['Accepting proposal ' + secondHighestBidValue];
		
		loop t over: tail {
			write '(Time ' + time + '): ' + name + ' reject proposal from ' + Guest(t.sender).name;
			do reject_proposal message: t contents: ['Refecting proposal from ' + Guest(t.sender).name];
		}
		
		do releaseAllGuestsFromAuction;
		do endAuction;
		
		write name + ' gained value from Vickrey auction for ' + length(valueGained) + ' auctions: ' + sum(valueGained);
		write Guest(highestBid.sender).name + ' paid in ' + length(valueGained) + ' Vickrey auctions: ' + sum(valueGained);
	}
	
	action releaseAllGuestsFromAuction {
		loop i over: interestedParticipants {
			do stopGuestFromParticipatingInAuction(i);
		}
	}
	
	action stopGuestFromParticipatingInAuction(Guest guest) {
		guest.isInAuction <- false;
		guest.myColor <- #red;
	}
	
	action endAuction {
		interestedParticipants <- [];
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
	float acceptablePrice <- 320;
	string interestedGenre <- 'clothes';
	bool isInAuction <- false;
	list<float> dutchAuctionsParticipated;
	list<float> englishAuctionsParticipated;
	list<float> vickreyAuctionsParticipated;
	
	reflex read_inform when: !empty(informs) and time mod 2 = 1 {
		loop i over: informs {
			write '(Time ' + time + '): ' + name + ' receives message with content: ' + (string(i.contents));
			if (length(list(i.contents)) > 1 and i.contents[1] != AUCTION_ENDED) { // entering any type of auction
				write '(Time ' + time + '): ' + name + ' will participate in auction';
				do participateInAuction;
				do end_conversation message: i contents: ['Understood message from ' + agent(i.sender).name, self];
			} else {
				do end_conversation message: i contents: ['Understood message from ' + agent(i.sender).name];
			}
		}
	}
	
	reflex receive_cfp_from_auctioneer when: !empty(cfps) and time mod 2 = 1 {
		message proposalFromAuctioneer <- cfps[0];
		do handleCfpMessage(proposalFromAuctioneer);
	}
	
	action handleCfpMessage(message proposalFromAuctioneer) {
		float priceToPropose <- list(proposalFromAuctioneer.contents)[1] as float;
		string auctionType <- proposalFromAuctioneer.contents[2];
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' 
			+ agent(proposalFromAuctioneer.sender).name;
			
		if (auctionType = VICKREY_BID_AUCTION_TYPE) {
			do propose message: proposalFromAuctioneer contents: [rnd(200, 300)];
		} else {
			write 'Acceptable price ' + acceptablePrice;
			if (auctionType = ENGLISH_AUCTION_TYPE) {
				priceToPropose <- priceToPropose + rnd(10, 50);
			}
			if (priceToPropose > acceptablePrice) {
				write '(Time ' + time + '): ' + ' buyer ' + name + ' rejects offer';
				do refuse message: proposalFromAuctioneer contents: ['Rejecting offer'];
			} else {
				write 'Willing to pay ' + priceToPropose;
				write '(Time ' + time + '): ' + ' buyer ' + name + ' proposes price ' + priceToPropose;
				do propose message: proposalFromAuctioneer contents: [priceToPropose];
			}
		}
		
	}
	
	reflex receive_requests when: !empty(requests) and time mod 2 = 1 {
		message requestFromInitiator <- requests[0];
		write '(Time ' + time + '): ' + ' buyer ' + name + ' pays request ' + requestFromInitiator;
		write 'agree message';
		do agree message: requestFromInitiator contents: ['I will'] ;
		
		write 'inform the initiator';
		do inform message: requestFromInitiator contents: ['I have paid bid'] ;
	}
	
	reflex dance when: !isInAuction {
		do wander;
	}
	
	action participateInAuction {
		isInAuction <- true;
		myColor <- #green;
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
			species EnglishAuctioneer;
			species VickreyAuctioneer;
		}	
	}
}

