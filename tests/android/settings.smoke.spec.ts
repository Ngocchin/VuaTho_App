import assert from 'node:assert/strict';

describe('Android emulator smoke', () => {
  it('opens the Android Settings app in a native session', async () => {
    const currentPackage = await browser.getCurrentPackage();

    assert.equal(currentPackage, 'com.android.settings');
  });
});
