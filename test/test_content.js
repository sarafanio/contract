const SarafanToken = artifacts.require('SarafanToken');
const SarafanContent = artifacts.require('SarafanContent');
const SarafanPeering = artifacts.require('SarafanPeering');

contract("SarafanContent", accounts => {
  it("should allow to post publication but not duplicates", async () => {
    const magnet = '0x00000000000000000000000000000001';
    let token = await SarafanToken.deployed();
    let instance = await SarafanContent.deployed(token.address);
    token.approve(instance.address, 10000);
    await instance.post(magnet, 9000000);

    let catched = null;
    try {
      await instance.post(magnet, 1000000);
    } catch(err) {
      assert.equal(err.reason, 'Such magnet already published');
      catched = err;
    }
    assert(catched, "No error raised for duplicated magnet");
  });

  it("should not accept too large publications", async () => {
    const magnet = '0x00000000000000000000000000000001';
    let token = await SarafanToken.deployed();
    let instance = await SarafanContent.deployed(token.address);
    token.approve(instance.address, 10000);

    let catched = null;
    try {
      await instance.post(magnet, 11000000);
    } catch (err) {
      assert.equal(err.reason, 'Content size should be less than 10Mb');
      catched = err;
    }
    assert(catched, "No error raised for oversized publication content");
  });

  it("should be 13 SRFN fee for publication of 1Mb for 12 months", async () => {
    const magnet = '0x00000000000000000000000000000002';
    let token = await SarafanToken.deployed();
    let instance = await SarafanContent.deployed(token.address);
    token.approve(instance.address, 14);

    await instance.post(magnet, 1000000);
    assert.equal(await token.allowance(accounts[0], instance.address), 1);
  });

  it('should allow awards', async () => {
    const magnet = '0x00000000000000000000000000000003';
    let token = await SarafanToken.deployed();
    let instance = await SarafanContent.deployed(token.address);
    token.approve(instance.address, 25);

    await instance.post(magnet, 1000000);

    await instance.award(magnet, 11);

    assert.equal(await token.allowance(accounts[0], instance.address), 1);
  })

  it('should allow abuse', async () => {
    const magnet = '0x00000000000000000000000000000004';
    let token = await SarafanToken.deployed();
    let instance = await SarafanContent.deployed(token.address);
    token.approve(instance.address, 64);

    await instance.post(magnet, 1000000);

    await instance.abuse(magnet, '0x00000000000000000000000000000000');

    assert.equal(await token.allowance(accounts[0], instance.address), 1);
  })
});
