(() => {
  const root = document.getElementById('nui-root');
  const els = {
    zoneName: document.getElementById('zoneName'),
    textUI: document.getElementById('textUI'),
    textUIColor: document.getElementById('textUIColor'),
    textUIColorPicker: document.getElementById('textUIColorPicker'),
    textUIPosition: document.getElementById('textUIPosition'),
    zoneSize: document.getElementById('zoneSize'),
    zoneSizeValue: document.getElementById('zoneSizeValue'),
    disarm: document.getElementById('disarm'),
    invincible: document.getElementById('invincible'),
    speedLimit: document.getElementById('speedLimit'),
    speedLimitValue: document.getElementById('speedLimitValue'),
    blipID: document.getElementById('blipID'),
    blipColor: document.getElementById('blipColor'),
    cancelBtn: document.getElementById('cancelBtn'),
    confirmBtn: document.getElementById('confirmBtn'),
  };

  function closeUI() {
    root.classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/cancel`, { method: 'POST', body: '{}' });
  }

  function applyDefaults(d) {
    els.zoneName.value = d.zoneName ?? 'Greenzone';
    els.textUI.value = d.textUI ?? 'Greenzone active';
    els.textUIColor.value = d.textUIColor ?? '#FF5A47';
    els.textUIColorPicker.value = d.textUIColor ?? '#FF5A47';
    els.textUIPosition.value = d.textUIPosition ?? 'top-center';
    els.zoneSize.value = d.zoneSize ?? 50;
    els.zoneSizeValue.textContent = String(els.zoneSize.value);
    els.disarm.checked = Boolean(d.disarm ?? true);
    els.invincible.checked = Boolean(d.invincible ?? true);
    els.speedLimit.value = d.speedLimit ?? 0;
    els.speedLimitValue.textContent = String(els.speedLimit.value);
    els.blipID.value = d.blipID ?? 487;
    els.blipColor.value = d.blipColor ?? 1;
  }

  function openUI(payload) {
    applyDefaults(payload || {});
    root.classList.remove('hidden');
  }

  // Live value displays
  els.zoneSize.addEventListener('input', () => {
    els.zoneSizeValue.textContent = String(els.zoneSize.value);
  });
  els.speedLimit.addEventListener('input', () => {
    els.speedLimitValue.textContent = String(els.speedLimit.value);
  });
  els.textUIColorPicker.addEventListener('input', () => {
    els.textUIColor.value = els.textUIColorPicker.value;
  });
  els.textUIColor.addEventListener('input', () => {
    // basic sanitize
    if (!els.textUIColor.value.startsWith('#')) els.textUIColor.value = '#' + els.textUIColor.value.replace(/[^0-9a-fA-F]/g,'');
  });

  // Buttons
  els.cancelBtn.addEventListener('click', () => closeUI());
  els.confirmBtn.addEventListener('click', () => {
    const data = {
      zoneName: els.zoneName.value.trim(),
      textUI: els.textUI.value.trim(),
      textUIColor: els.textUIColor.value.trim(),
      textUIPosition: els.textUIPosition.value,
      zoneSize: parseInt(els.zoneSize.value, 10) || 50,
      disarm: !!els.disarm.checked,
      invincible: !!els.invincible.checked,
      speedLimit: parseInt(els.speedLimit.value, 10) || 0,
      blipID: parseInt(els.blipID.value, 10) || 487,
      blipColor: parseInt(els.blipColor.value, 10) || 1,
    };
    root.classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/confirm`, { method: 'POST', body: JSON.stringify(data) });
  });

  // Escape to cancel
  window.addEventListener('keydown', (ev) => {
    if (ev.key === 'Escape') {
      closeUI();
    }
  });

  // NUI messages
  window.addEventListener('message', (event) => {
    if (!event || !event.data) return;
    const { action, data } = event.data;
    if (action === 'open') openUI(data || {});
    else if (action === 'close') root.classList.add('hidden');
  });

  // Close by default on load
  root.classList.add('hidden');
})();