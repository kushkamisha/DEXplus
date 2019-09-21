function callContract() {
    const jsonInterface = [{ "constant": true, "inputs": [], "name": "getName", "outputs": [{ "internalType": "string", "name": "", "type": "string" }], "payable": false, "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_addr", "type": "address" }], "payable": false, "stateMutability": "nonpayable", "type": "constructor" }]
    const address = '0x13A31b34F5999D6677C41559E7e8e2CeF9ce7674' // Caller
    const contract = new web3.eth.Countract(jsonInterface, address)

    console.log({ contract })
    contract.methods.getName().call((err, name) => {
        console.log({ name })
    })
}

$(document).ready(function() {

    ethereum.enable()
    .then(function (accounts) {
        console.log({ accounts })
        
        callContract()
    })
    .catch(function (error) {
        console.error(error)
    })
});

