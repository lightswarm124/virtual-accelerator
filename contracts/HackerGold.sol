
import "StandardToken.sol";

pragma solidity ^0.4.0;

/**
 *
 * Hacker gold is the official token of 
 * the <hack.ether.camp> hackathon. 
 *
 * todo: brief explained
 *
 * todo: white paper link
 *
 */
contract HackerGold is StandardToken {

    
    string public name = "HackerGold";                   
    uint8  public decimals = 3;                 
    string public symbol = "HKG";
    
    // 1 ether = 200 hkg
    uint BASE_PRICE = 200;
    
    // total value in wei
    uint totalValue;
    
    // multisig holding the value
    address wallet;

    struct milestones_struct {
      uint p1;
      uint p2; 
      uint p3;
      uint p4;
      uint p5;
      uint p6;
    }
    milestones_struct milestones;
    

    function HackerGold(address multisig) {
        
        wallet = multisig;

        // set time periods for sale
        milestones = milestones_struct(
        
          1476972000,  // P1: GMT: 20-Oct-2016 14:00  => The Sale Starts
          1478181600,  // P2: GMT: 03-Nov-2016 14:00  => 1st Price Ladder 
          1479391200,  // P3: GMT: 17-Nov-2016 14:00  => Price Stable, 
                       //                                Hackathon Starts
          1480600800,  // P4: GMT: 01-Dec-2016 14:00  => 2nd Price Ladder
          1481810400,  // P5: GMT: 15-Dec-2016 14:00  => Price Stable
          1482415200   // P6: GMT: 22-Dec-2016 14:00  => Sale Ends, Hackathon Ends
        );
                
    }
    
    
    /**
     * Default function : called on ether sent
     */
    function () payable {
        createHKG(msg.sender);
    }
    
    /**
     * Creates HKG tokens
     * 
     * @param holder token holder
     */
    function createHKG(address holder) payable {
        
        if (now < milestones.p1) throw;
        if (now > milestones.p6) throw;
        if (msg.value == 0) throw;
    
        // safety cap
        if (getTotalValue() + msg.value > 4000000 ether) throw; 
    
        uint tokens = msg.value / 1000000000000000 * getPrice();

        totalSupply += tokens;
        balances[holder] += tokens;
        totalValue += msg.value;
        
        if (!wallet.send(msg.value)) throw;
    }
    
    /**
     * getPrice() - function that denotes complete price 
     *              structure during the sale.
     *
     */
    function getPrice() constant returns (uint result){
        
        if (now < milestones.p1) return 0;
        
        if (now >= milestones.p1 && now < milestones.p2){
        
            return BASE_PRICE;
        }
        
        if (now >= milestones.p2 && now < milestones.p3){
            
        
            uint days_in = 1 + (now - milestones.p2) / (60 * 60 *24); 
            return BASE_PRICE - days_in * 25 / 7;  // daily decrease 3.5
        }

        if (now >= milestones.p3 && now < milestones.p4){
        
            return BASE_PRICE / 4 * 3;
        }
        
        if (now >= milestones.p4 && now < milestones.p5){
            
            days_in = 1 + (now - milestones.p4) / (60 * 60 *24); 
            return (BASE_PRICE / 4 * 3) - days_in * 25 / 7;  // daily decrease 3.5
        }

        if (now >= milestones.p5 && now < milestones.p6){
        
            return BASE_PRICE / 2;
        }
        
        if (now >= milestones.p6){

            return 0;
        }

     }
    
    /**
     *
     *
     */
    function getTotalSupply() constant returns (uint result){
        return totalSupply;
    } 

    
    function getNow() constant returns (uint result) {
        return now;
    }

    function getTotalValue() constant returns (uint result) {
        return totalValue;  
    }
}
