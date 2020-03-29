const SarafanToken = artifacts.require('SarafanToken');
const SarafanContent = artifacts.require('SarafanContent');
const SarafanPeering = artifacts.require('SarafanPeering');

contract("SarafanToken", accounts => {

  it("should put 300M tokens to account owner", async () => {
    let instance = await SarafanToken.deployed();

    let balance = await instance.balanceOf(accounts[0]);
    assert.equal(balance.toNumber(), 300000000);
  });

  it("should implement erc-20 interface", async () => {
    let instance = await SarafanToken.deployed();

    await instance.approve(accounts[1], 1000);

    await instance.transferFrom(accounts[0], accounts[2], 1000, {from: accounts[1]});

    assert.equal(await instance.balanceOf(accounts[1]), 0);
    assert.equal(await instance.balanceOf(accounts[2]), 1000);
  })

  it("should convert 1 ether to 1M SRFN at ICO start", async () => {
    let instance = await SarafanToken.deployed();

    await web3.eth.sendTransaction({
      from: accounts[1],
      to: instance.address,
      value: web3.utils.toWei('1')
    });

    let balance = await instance.balanceOf(accounts[1]);
    assert.equal(balance.toNumber(), 1000000);
  });

  it("should allow to link and change related contracts", async () => {
    let instance = await SarafanToken.deployed();
    let content = await SarafanContent.deployed(instance.address);
    let peering = await SarafanPeering.deployed(instance.address);

    const oldSupply = (await instance.totalSupply()).toNumber();
    await instance.setContentContract(content.address);
    await instance.setPeeringContract(peering.address);

    assert.equal(await instance.contentContract(), content.address);
    assert.equal(await instance.peeringContract(), peering.address);

    assert.equal((await instance.balanceOf(peering.address)).toNumber(),
                 20000000);
  });

  it("should allow payouts", async () => {
    let instance = await SarafanToken.deployed();

    const value = web3.utils.toWei('1');

    await web3.eth.sendTransaction({
      from: accounts[1],
      to: instance.address,
      value: value
    });

    await instance.payout(accounts[0], value);
  });

  it("should allow change megabyte month cost", async () => {
    let instance = await SarafanToken.deployed();

    await instance.setMegabyteMonthCost(2);

    assert.equal(await instance.megabyteMonthCost(), 2)
  });

  it("should be possible to burn some tokens", async () => {
    let instance = await SarafanToken.deployed();
    const oldSupply = await instance.totalSupply();
    const oldBalance = await instance.balanceOf(accounts[0]);
    await instance.burn(100);
    assert.equal(await instance.totalSupply(), oldSupply - 100, "Wrong amount burned");
    assert.equal(await instance.balanceOf(accounts[0]), oldBalance - 100)
  })
});
