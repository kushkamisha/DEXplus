$(document).ready(function() {
  const web3 = new Web3(window.web3.currentProvider);

  const address = "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07"

  const contract = window.web3.eth.contract(abi, address)
});

