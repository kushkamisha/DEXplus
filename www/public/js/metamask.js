const Eth = require('ethjs-query')
const EthContract = require('ethjs-contract')

const platformData = require('./platform');
const erc721Data = require('./erc721');
const erc20Data = require('./erc20');

const initContract = (contract, abi, address) => contract(abi).at(address)

const eth = new Eth(web3.currentProvider)
const contract = new EthContract(eth)

const silence = initContract(contract, erc20Data.abi, erc20Data.address)
const kittens = initContract(contract, erc721Data.abi, erc721Data.address)
const platform = initContract(contract, platformData.abi, platformData.address)

const ownedKittens = []
let addr = ''

const startApp = () => {
    loadUserInfo()
    loadExchangeOrders()
}

window.fillOrder = (orderId, value) =>
    callContract(platform, 'fillERC721order', orderId, { from: addr, gas: 5000000, value })
        .then(console.log)

const loadUserInfo = () => {
    addr = web3.eth.accounts[0]

    $('#address').text(addr)

    web3.eth.getBalance(addr, (err, res) => {
        if (err) throw err
        const balance = `${web3.fromWei(res, 'ether')} ETH`
        $('#eth-balance').text(balance)
    })

    callContract(silence, 'balanceOf', addr.toString('hex'))
        .then(res => {
            const balance = `${web3.fromWei(res[0], 'ether')} `
            $('#erc20-balance').text(balance)
        })
    callContract(silence, 'SYMBOL').then(res => $('#erc20-symbol').text(res[0]))

    callContract(kittens, 'balanceOf', addr.toString('hex'))
        .then(res => res[0].toNumber())
        .then(num => {
            for (let i = 0; i < num; i++) {
                callContract(kittens, 'tokenOfOwnerByIndex', addr.toString('hex'), i)
                    .then(res => res[0].toNumber())
                    .then(id => {
                         callContract(kittens, 'tokenName', `${id}`)
                            .then(res => {
                                const kittenName = res[0].toString()
                                ownedKittens.push({ id, kittenName })
                                return kittenName
                            })
                            .then(kitten => $('#erc721-balance').append(`${kitten}, `))
                    })
            }
        })
    
}

const loadExchangeOrders = async() => {
    const count = (await callContract(platform, 'ordersCountERC721'))[0].toNumber()

    const promices = [];
    for (let i = 0; i < count; i++) promices.push(callContract(platform, 'ordersERC721', i))
    const orders = (await Promise.all(promices)).flat().filter(e => e.status)

    for (const order of orders) {
        const { orderId, index, owner, price, expireDate } = order

        $('#ordersTable').append(`
            <tr>
                <th scope="row">${orderId}</th>
                <td>CryptoKittens</td>
                <td>${index}</td>
                <td>${owner}</td>
                <td>${price / 1e18}</td>
                <td>${(new Date(expireDate * 1000)).toString().slice(0, 24)}</td>
                <td><button type="button" class="btn btn-primary" onclick="window.fillOrder(${orderId}, ${price})">Fill an order</button></td>
            </tr>`)
    }
}

const callContract = async (contract, method, ...params) => await contract[method](...params)

/*******************************************/

$('#place-order').click(() => {
    console.log(ownedKittens)
    const price = `${$('#erc721-price').val() * 1e18}`
    const kittenName = $('#erc721-name').val()
    const expireDate = $('#erc721-expireDate').val()
    const expireTime = $('#erc721-expireTime').val()

    const expire = new Date(`${expireDate}T${expireTime}:00`).getTime() / 1000

    const kitten = ownedKittens.filter(obj => obj.kittenName === kittenName)
    const kittenId = kitten[0].id

    console.log('approve', platformData.address.toString('hex'), kittenId,
    { from: addr, gas: 5000000 })

    callContract(kittens, 'approve', platformData.address.toString('hex'), kittenId,
        { from: addr, gas: 5000000 }).then(res => {
            console.log({ res })

            callContract(
                platform,
                'createERC721order',
                price,
                kittenId,
                0,
                expire,
                {
                    from: addr,
                    gas: 5000000
                }
            ).then(res => console.log(res))
        })
})

/*******************************************/

window.addEventListener('load', () => {
    if (typeof web3 !== 'undefined') startApp()
})
