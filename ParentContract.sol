pragma solidity ^0.4.0;

contract ParentContract{
    address public donator;

function ParentContract() {
    donatar = msg.sender;
}

function () payble {
    donator - msg.sender;
    }
    function setDonator(addres _donator) {
        donator = _donator;
        }
}

contract ChildContract is ParentContract {     /// наследуемый контракт
    function setRealDonator(addres _donator) {
        if (msg.value > 1 * 1 ether) {
            setDonator(_donator);
        }
    }
}