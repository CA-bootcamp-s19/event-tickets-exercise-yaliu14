pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string url;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */

    modifier isOwner () {require (msg.sender == owner); _;}

    constructor() public {
        owner = msg.sender;
        idGenerator = 0;
    }
    
    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _url, uint _numTickets) public isOwner returns (uint){
        uint _eventId = idGenerator;
        events[_eventId] = Event({description: _description,
                                  url: _url,
                                  totalTickets: _numTickets,
                                  sales: 0,
                                  isOpen: true});
        idGenerator++;
        emit LogEventAdded(_description, _url, _numTickets, _eventId);
        return _eventId;
    }

    
    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _eventId) public view returns (string memory description, string memory url, uint totalTickets, uint sales, bool isOpen) {
        description = events[_eventId].description;
        url = events[_eventId].url;
        totalTickets = events[_eventId].totalTickets;
        sales = events[_eventId].sales;
        isOpen = events[_eventId].isOpen;
        return (description, url, totalTickets, sales, isOpen);
    }

    
    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint eventId, uint numTickets) external payable{
        uint ticketsCost = numTickets*PRICE_TICKET;
        address buyer = msg.sender;
        require (eventId < idGenerator, "no such event");
        require (events[eventId].isOpen, "event is not open");
        require (msg.value >= ticketsCost, "transaction value insufficient");
        require (events[eventId].totalTickets >= events[eventId].sales + numTickets , "not enough tickets in stock");
        events[eventId].buyers[buyer] += numTickets;
        events[eventId].sales += numTickets;
        msg.sender.transfer(msg.value-ticketsCost);
        emit LogBuyTickets(buyer, eventId, numTickets);
    }

    
    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint eventId) external{
        address requester = msg.sender;
        require (events[eventId].buyers[requester] > 0, "requester has not purchased tickets");
        uint numTickets = events[eventId].buyers[requester];
        uint ticketsCost = numTickets*PRICE_TICKET;
        events[eventId].totalTickets += numTickets;
        events[eventId].buyers[requester] -= numTickets;
        msg.sender.transfer(ticketsCost);
        emit LogGetRefund(requester, eventId, numTickets);
    }

    
    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint eventId) external view returns (uint) {
        return events[eventId].buyers[msg.sender];
    }
    

    
    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint eventId) external isOwner{
        require(events[eventId].isOpen, "this event is not open");
        events[eventId].isOpen = false;
        uint salesBalance = events[eventId].sales*PRICE_TICKET;
        owner.transfer(salesBalance);
        emit LogEndSale(owner, salesBalance, eventId);
    }
    


}
