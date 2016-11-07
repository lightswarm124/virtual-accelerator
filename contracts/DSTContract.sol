import "StandardToken.sol";
import "EventInfo.sol";
import "HackerGold.sol";

pragma solidity ^0.4.2;

/*
 * DSTContract - DST stands for decentralized standard team.
 *
 *
 */
contract DSTContract is StandardToken{


    address   selfAddress;

    address   executive; 
    
    // todo: 
    mapping (address => bool) executiveTeam; 
    
    EventInfo eventInfo;
    
    // Indicateds where the DST is threaded
    address virtualExchangeAddress;
    
    HackerGold hackerGold;
        
    mapping (address => uint256) votingRights;


    // 1 - HKG => DST qty; tokens for 1 HKG
    uint hkgPrice;
    
    // 1 - Ether => DST qty; tokens for 1 Ether
    uint etherPrice;
    
    string public name = "...";                   
    uint8  public decimals = 3;                 
    string public symbol = "...";
    
    bool ableToIssueTokens = true; 
    uint preferedQtySold;
    uint collectedHKG; 
    
    
    // Proposal of the funds spending
    mapping (bytes32 => Proposal) proposals;

    enum ProposalCurrency { HKG, ETHER }
    ProposalCurrency myCurrency;
    
       
    struct Proposal{
        
        bytes32 id;
        uint value;
        uint votindEndTS;
        
        string urlDetails;
        
        uint votesObjecting;
        
        address submitter;
        bool redeemed;

        ProposalCurrency proposalCurrency;
        
        mapping (address => bool) voted;
    }
    uint counterProposals;
    uint timeOfLastProposal;
    
    Proposal[] listProposals;
    
    /**
     * Impeachment process proposals
     */
    uint lastTimeImpProposed;
    ImpeachmentProposal currentImpProposal;
    
    struct ImpeachmentProposal{
        
        address newExecutive;
        uint timeSubmited;
        
        uint votesYes;
        uint votesNo;
        
        
    }
    
    
    event PriceHKGChange(uint qtyForOneHKG);
    event BuyForHKGTransaction(uint tokensAmount, uint qtyForOneHKG, uint tokensAvailable, uint tokensSold);
    
    event ProposalRequestHKGSubmitted(bytes32 id, uint value, uint timeEnds, string url, address sender);
    
    event ObjectedVote(bytes32 id, address voter, uint votes);
    
    
    /*
     * 
     *  Set date for early adapters
     *
     */ 
    function DSTContract(EventInfo eventInfoAddr, HackerGold hackerGoldAddr, string dstName, string dstSymbol){
    
      selfAddress = this; 
      executive   = msg.sender;  
      name        = dstName;
      symbol      = dstSymbol;

      hackerGold = HackerGold(hackerGoldAddr);
      eventInfo  = EventInfo(eventInfoAddr);
    }
    

    function() payable {
        
        // If the hack event is not over return 
        // sent ether.
        if (now < eventInfo.getEventEnd()) {
            throw;
        }
        
        
        uint tokens = msg.value / (1 finney) * etherPrice;
        
        // check if demand of tokens is 
        // overflow the suply 
        if (balances[this] < tokens){
            
            tokens = balances[this];
            uint retEther = msg.value - tokens / etherPrice * (1 finney);
        
            // return left ether 
            if (!msg.sender.send(retEther)) throw;
        }
        
        
        // do transfer
        balances[msg.sender] += tokens;
        balances[this] -= tokens;
        
        // ... event for transfer
    }

    /**
     * 
     * 
     */
    function spendHKG(uint value, address targetAddr){
        
        // validate time frame
        // only executive can do it
        

        
    }
    
    
    /**
     * 
     * qtyForOneHKG - 
     * 
     */    
     function setHKGPrice(uint qtyForOneHKG) onlyExecutive {
         
         hkgPrice = qtyForOneHKG;
         PriceHKGChange(qtyForOneHKG);
     }
     
     
    
    /**
     * 
     * issuePreferedTokens - prefered tokens issued on the hackathon event
     *                       tain special rights
     * 
     */
    function issuePreferedTokens(uint qtyForOneHKG, 
                                 uint qtyToEmit) onlyExecutive 
                                                 onlyIfAbleToIssueTokens
                                                 onlyBeforeEnd
                                                 onlyAfterTradingStart {
        
        // the issuer of the token disabled futer issuance                                                        
        if (!ableToIssueTokens) {
            throw;
        }                
                
        // no issuence is allowed before enlisted on the
        // exchange 
        if (virtualExchangeAddress == 0x0) throw;
            
        totalSupply    += qtyToEmit;
        balances[this] += qtyToEmit;
        hkgPrice = qtyForOneHKG;
        
        
        // now spender can use balance in 
        // ammount of value from owner balance
        allowed[this][virtualExchangeAddress] = qtyToEmit;
        
        // rise event about the transaction
        Approval(this, virtualExchangeAddress, qtyToEmit);
        
        
        // ... todo: emit event for new tokens + price
        // DstTokensIssued(indexed uint qtyForOneEther, indexed uint qtyToEmit, indexed uint totalSupply)
    }

    
    
    
    /**
     * 
     * buyForHackerGold - on the hack event this function is available 
     *                    the buyer for hacker gold will gain votes to 
     *                    influence future proposals on the DST
     *    
     *  @param hkgValue - qty of this DST tokens for 1 HKG     
     * 
     */
    function buyForHackerGold(uint hkgValue) onlyBeforeEnd 
                                             returns (bool success) {
    

      // Validate that the caller is official accelerator HKG Exchange
      if (msg.sender != virtualExchangeAddress) throw;
      
      // todo: reduce issued tokens from total
      
      // todo: preferedQtySold +=...
    
    
      // Transfer token 
      address sender = tx.origin;
      
      uint tokensQty = hkgValue * hkgPrice;


      // Gain voting rights
      votingRights[sender] +=tokensQty;
      preferedQtySold += tokensQty;
      collectedHKG += hkgValue;
      
      
                
      transferFrom(this, 
                   virtualExchangeAddress, tokensQty);
      transfer(sender, tokensQty);        
            
      BuyForHKGTransaction(tokensQty, hkgPrice, balances[this], tokensQty);
        
      return true;
    }
    
    
    
    
    /**
     * 
     * issueTokens - function will issue tokens after the 
     *               event
     * 
     * @param qtyForOneEther - ...
     * @param qtyToEmit      - ...     
     *
     * @return - ammount of tokens issued
     */
    function issueTokens(uint qtyForOneEther, 
                         uint qtyToEmit) onlyAfterEnd 
                                         onlyExecutive {
         
        // If the user already declared end 
        // of issuence
        if (!ableToIssueTokens) {
            throw;
        }
         
         balances[this] += qtyToEmit;
         etherPrice = qtyForOneEther;
         totalSupply    += qtyToEmit;
    }
     
     
    // ... todo: setEtherPrice()
    

    /**
     *  disableTokenIssuance - function will disable any 
     *                         option for future issuence
     *
     *
     */
    function disableTokenIssuance() onlyExecutive{
        ableToIssueTokens = false;
        
        // todo: event for this
    }

    
     
    /**
     * 
     * 
     * 
     * 
     */
    function submitHKGProposal(uint requestValue, string url) onlyAfterEnd
                                                              onlyExecutive returns (bytes32 resultId, bool resultSucces){
        

        // If there is no 2 months over since the last event.
        // There is no posible to get any HKG. After 2 months
        // all the HKG is available. 
        if (now < (eventInfo.getEventEnd() + 8 weeks)) {
            throw;
        }


        // Possible to submit a proposal once 2 weeks 
        if (now < (timeOfLastProposal + 2 weeks)) throw;

                
        uint percent = collectedHKG / 100;
        
        // validate the ammount is legit
        // first 5 proposals should be less than 20% 
        if (counterProposals <= 5 && 
            requestValue     >  20 * percent) throw;
        
        
        // if remained value is less than requested 
        // gain all.
        if (requestValue > getHKGOwned()) 
            requestValue = getHKGOwned();
        
    
        // set id of the proposal
        // submit proposal to the map
        bytes32 id = sha3(msg.data, now);
        uint timeEnds = now + 10 days; 
        
        Proposal memory newProposal = Proposal(id, requestValue, timeEnds, url, 0, msg.sender, false, ProposalCurrency.HKG);
        proposals[id] = newProposal;
        listProposals.push(newProposal);
        
        ++counterProposals;
        timeOfLastProposal = now;                
                
        ProposalRequestHKGSubmitted(id, requestValue, timeEnds, url, msg.sender);
        
        return (id, true);        
    }  
    
    
    
    /**
     * 
     * 
     * 
     */
     function objectProposal(bytes32 id){
         
        Proposal memory proposal = proposals[id];
         
        // check proposal exist 
        if (proposals[id].id == 0) throw;

        // check already redeemed
        if (proposals[id].redeemed) throw;
         
        // ensure objection time
        if (now >= proposals[id].votindEndTS) throw;
         
        if (proposals[id].voted[msg.sender]) throw;
         
         // submit votes
         uint votes = votingRights[msg.sender];
         proposals[id].votesObjecting += votes;
         
         uint idx = getIndexByProposalId(id);
         listProposals[idx] = proposals[id];   

         ObjectedVote(id, msg.sender, votes);         
     }
     
     
     function getIndexByProposalId(bytes32 id) returns (uint result){
         
         for (uint i = 0; i < listProposals.length; ++i){
             if (id == listProposals[i].id) return i;
         }
     }
    
    
//    event here_event(bool redeemed);  // REMOVE IT !!!
//    here_event(proposal.redeemed);// REMOVE IT !!!
   
    /**
     * 
     * 
     * @param id bytes32: the id of the proposal to redeem
     */
    function redeemProposalFunds(bytes32 id) onlyExecutive {
        
        if (proposals[id].id == 0) throw;
        if (proposals[id].submitter != msg.sender) throw;

        if (proposals[id].proposalCurrency == ProposalCurrency.HKG){
            
            // ensure objection time
            if (now < proposals[id].votindEndTS) throw;
                               
            // check votes objection => 55% of total votes
            uint objectionThreshold = preferedQtySold / 100 * 55;
            if (proposals[id].votesObjecting  > objectionThreshold) throw;
             
            // check already redeemed
            if (proposals[id].redeemed) throw;
            
            // execute the proposal 
            proposals[id].redeemed = true; 
            hackerGold.transfer(proposals[id].submitter, proposals[id].value);      
            
            
        } else {
            
            // ... TODO: Ether redeem will be here 
        }
        
    }
    
    
    function getAllTheFunds(){
        // todo... after 6 months you can request all the HKG value no mater what.
    }
    
    
    /**
     * 
     * 
     * 
     */             
     function startImpeachmentProcess(){
         
         // todo: check there is 1 months since last one
         
         
     }
    
    
    /**
     * 
     */
    function voteForImeachment(bool yes){        
    } 
    
    
    function getEther(){
        
        // proposals are the same as with HKG 
        // Condition_1: the issuing ether is done
        // Condition_2: all the tokens are sold
        
        // ... possible close the sale and burn the rest of tokens
    }
    
    
    /**
     * 
     *  
     * 
     */
    function executeImpeachment(){
        
        // check there is 50% voters
        // check there is 70% vote Yes
        
        // set new executive 
        // tokens transfered to new executive
        
        
    }
    
    
    
    /**
     * 
     *   Constant Function 
     * 
     */ 
    
    function votingRightsOf(address _owner) constant returns (uint256 result) {
        result = votingRights[_owner];
    }
    
    function getPreferedQtySold() constant returns (uint result){
        return preferedQtySold;
    }
    
    function setVirtualExchange(address virtualExchangeAddr){
        virtualExchangeAddress = virtualExchangeAddr;
    }

    function getHKGOwned() constant returns (uint result){
        return hackerGold.balanceOf(this);
    }
    
    function getExecutive() constant returns (address result){
        return executive;
    }
    
    function getHKGPrice() constant returns (uint result){
        return hkgPrice;
    }

    function getDSTName() constant returns(string result){
        return name;
    }    
    
    function getDSTNameBytes() constant returns(bytes32 result){
        return convert(name);
    }    

    function getDSTSymbol() constant returns(string result){
        return symbol;
    }    
    
    function getDSTSymbolBytes() constant returns(bytes32 result){
        return convert(symbol);
    }    


    function getAddress() constant returns (address result) {
        return selfAddress;
    }
    
    function getTotalSupply() constant returns (uint result) {
        return totalSupply;
    } 
    
    function getEtherValue() constant returns (uint results) {        
        return this.balance;
    }
    
    function getCounterProposals() constant returns (uint result){
        return counterProposals;
    }
        
    function getProposalIdByIndex(uint i) constant returns (bytes32 result){
        return listProposals[i].id;
    }    

    function getProposalObjectionByIndex(uint i) constant returns (uint result){
        return listProposals[i].votesObjecting;
    }    
    
    
    function convert(string key) returns (bytes32 ret) {
            if (bytes(key).length > 32) {
                throw;
            }      

            assembly {
                ret := mload(add(key, 32))
            }
    }    
    
    // ********************* //
    // *     Modifiers     * //
    // ********************* //    
 
    modifier onlyBeforeEnd() { if (now  >=  eventInfo.getEventEnd()) throw; _; }
    modifier onlyAfterEnd()  { if (now  <   eventInfo.getEventEnd()) throw; _; }
    
    modifier onlyAfterTradingStart()  { if (now  < eventInfo.getTradingStart()) throw; _; }
    
    modifier onlyExecutive()     { if (msg.sender != executive && 
                                       executiveTeam[msg.sender] == false)   throw; _; }
                                       
    modifier onlyIfAbleToIssueTokens()  { if (!ableToIssueTokens) throw; _; } 
    
    
}


 
