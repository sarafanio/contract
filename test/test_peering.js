const SarafanToken = artifacts.require('SarafanToken');
const SarafanContent = artifacts.require('SarafanContent');
const SarafanPeering = artifacts.require('SarafanPeering');

contract("SarafanPeering", accounts => {
  it("should register new peers", async () => {
    let token = await SarafanToken.deployed();
    let instance = await SarafanPeering.deployed(token.address);

    const hostname = '0x00000000000000000000000000000001';
    instance.register(hostname);
  });
  it("should commit peer work but not twice", async () => {
    let token = await SarafanToken.deployed();
    let instance = await SarafanPeering.deployed(token.address);

    const datahash = '0x00000000000000000000000000000001';
    await instance.commit(datahash, 1000, 1);
    try {
      await instance.commit(datahash, 1000, 1);
    } catch(err) {
      assert.equal(err.reason, "This data hash already committed")
    };
  });
  it("should be possible to verify commitment", async () => {
    let token = await SarafanToken.deployed();
    let instance = await SarafanPeering.deployed(token.address);

    const datahash = '0x00000000000000000000000000000002';
    await instance.commit(datahash, 1000, 1);

    await instance.verify(datahash, 100000);
  });
  it("should be possible to reject commitment", async () => {
    let token = await SarafanToken.deployed();
    let instance = await SarafanPeering.deployed(token.address);

    const datahash = '0x00000000000000000000000000000003';
    await instance.commit(datahash, 1000, 1);

    await instance.reject(datahash);
  });
  it("should be only one verify or reject from peer", async () => {
    let token = await SarafanToken.deployed();
    let instance = await SarafanPeering.deployed(token.address);

    const datahash = '0x00000000000000000000000000000004';
    await instance.commit(datahash, 1000, 1);

    await instance.reject(datahash);
    let catched = null;
    try {
      await instance.verify(datahash, 50000);
    } catch(err) {
      catched = err;
      assert.equal(err.reason, "Already verified")
    }
    assert(catched != null, "No error on second verify");
  })
  it("should be possible to payout storage reward", async () => {
    let token = await SarafanToken.deployed();
    let instance = await SarafanPeering.deployed(token.address);

    await token.setPeeringContract(instance.address);

    const datahash = '0x00000000000000000000000000000005';
    await instance.commit(datahash, 720000000, 1);

    await instance.verify(datahash, 100000);

    await instance.setWaitPayout(false);

    const prevBalance = await token.balanceOf(accounts[1]);
    await instance.payout(datahash, accounts[1]);
    assert.equal(await token.balanceOf(accounts[1]), prevBalance.toNumber() + 1);
  });
});
