(() => {
  const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'Outlaw_GreenZone';
  const root = document.getElementById('nui-root');
  const headerTitle = document.querySelector('.tablet__title');
  const els = {
    designerView: document.getElementById('designerView'),
    removalView: document.getElementById('removalView'),
    removalList: document.getElementById('removalList'),
    removalEmpty: document.getElementById('removalEmpty'),
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

  const defaultTexts = {
    title: headerTitle ? headerTitle.textContent : '',
    confirm: els.confirmBtn ? els.confirmBtn.textContent : '',
    cancel: els.cancelBtn ? els.cancelBtn.textContent : '',
  };

  let currentView = 'designer';
  let removalStrings = {
    removeLabel: 'Remove zone',
    removeAllLabel: 'Remove all zones',
    empty: els.removalEmpty ? els.removalEmpty.textContent : 'No admin Green Zones are active.',
  };

  function hideRoot() {
    if (!root) return;
    root.classList.add('hidden');
    root.setAttribute('aria-hidden', 'true');
  }

  function showRoot() {
    if (!root) return;
    root.classList.remove('hidden');
    root.setAttribute('aria-hidden', 'false');
  }

  function closeUI() {
    hideRoot();
    fetch(`https://${resource}/cancel`, { method: 'POST', body: '{}' });
  }

  function setView(view, meta = {}) {
    currentView = view;

    if (headerTitle) {
      headerTitle.textContent = meta.title || defaultTexts.title;
    }

    if (els.cancelBtn) {
      els.cancelBtn.textContent = meta.cancelLabel || defaultTexts.cancel;
    }

    if (view === 'designer') {
      els.designerView?.classList.remove('is-hidden');
      els.designerView?.setAttribute('aria-hidden', 'false');
      els.removalView?.classList.add('is-hidden');
      els.removalView?.setAttribute('aria-hidden', 'true');
      if (els.confirmBtn) {
        els.confirmBtn.textContent = meta.confirmLabel || defaultTexts.confirm;
        els.confirmBtn.classList.add('btn--accent');
        els.confirmBtn.classList.remove('btn--danger');
        els.confirmBtn.disabled = false;
      }
    } else {
      els.designerView?.classList.add('is-hidden');
      els.designerView?.setAttribute('aria-hidden', 'true');
      els.removalView?.classList.remove('is-hidden');
      els.removalView?.setAttribute('aria-hidden', 'false');
      if (els.confirmBtn) {
        const label = meta.confirmLabel || removalStrings.removeAllLabel || defaultTexts.confirm;
        els.confirmBtn.textContent = label;
        els.confirmBtn.classList.remove('btn--accent');
        els.confirmBtn.classList.add('btn--danger');
      }
    }
  }

  function getValue(obj, key, fallback) {
    if (obj && Object.prototype.hasOwnProperty.call(obj, key) && obj[key] !== null && obj[key] !== undefined) {
      return obj[key];
    }
    return fallback;
  }

  function applyDefaults(d) {
    els.zoneName.value = getValue(d, 'zoneName', 'Greenzone');
    els.textUI.value = getValue(d, 'textUI', 'Greenzone active');
    const textColor = getValue(d, 'textUIColor', '#FF5A47');
    els.textUIColor.value = textColor;
    els.textUIColorPicker.value = textColor;
    els.textUIPosition.value = getValue(d, 'textUIPosition', 'top-center');
    els.zoneSize.value = getValue(d, 'zoneSize', 50);
    els.zoneSizeValue.textContent = String(els.zoneSize.value);
    const disarmDefault = getValue(d, 'disarm', true);
    els.disarm.checked = Boolean(disarmDefault);
    const invincibleDefault = getValue(d, 'invincible', true);
    els.invincible.checked = Boolean(invincibleDefault);
    els.speedLimit.value = getValue(d, 'speedLimit', 0);
    els.speedLimitValue.textContent = String(els.speedLimit.value);
    els.blipID.value = getValue(d, 'blipID', 487);
    els.blipColor.value = getValue(d, 'blipColor', 1);
  }

  function renderRemovalList(zones) {
    if (!els.removalList) return;
    els.removalList.innerHTML = '';

    if (!Array.isArray(zones) || zones.length === 0) {
      if (els.removalEmpty) {
        els.removalEmpty.textContent = removalStrings.empty;
        els.removalEmpty.classList.remove('is-hidden');
      }
      if (els.confirmBtn) {
        els.confirmBtn.disabled = true;
      }
      return;
    }

    if (els.removalEmpty) {
      els.removalEmpty.classList.add('is-hidden');
    }

    if (els.confirmBtn) {
      els.confirmBtn.disabled = false;
    }

    zones.forEach((zone) => {
      const card = document.createElement('div');
      card.className = 'removal-card';

      const info = document.createElement('div');
      info.className = 'removal-card__info';

      const title = document.createElement('div');
      title.className = 'removal-card__title';
      title.textContent = zone?.name || `Zone #${zone?.id ?? ''}`;
      info.appendChild(title);

      if (zone?.subtitle) {
        const subtitle = document.createElement('div');
        subtitle.className = 'removal-card__subtitle';
        subtitle.textContent = zone.subtitle;
        info.appendChild(subtitle);
      }

      card.appendChild(info);

      const removeBtn = document.createElement('button');
      removeBtn.type = 'button';
      removeBtn.className = 'btn btn--danger removal-card__remove';
      removeBtn.textContent = removalStrings.removeLabel;
      removeBtn.addEventListener('click', () => removeZone(zone?.id));
      card.appendChild(removeBtn);

      els.removalList.appendChild(card);
    });
  }

  function openDesigner(payload, meta) {
    setView('designer', meta);
    applyDefaults(payload || {});
    showRoot();
  }

  function openRemoval(payload) {
    removalStrings = {
      removeLabel: payload?.removeLabel || removalStrings.removeLabel,
      removeAllLabel: payload?.removeAllLabel || removalStrings.removeAllLabel,
      empty: payload?.empty || removalStrings.empty,
    };

    setView('removal', {
      title: payload?.title,
      confirmLabel: payload?.confirmLabel || removalStrings.removeAllLabel,
      cancelLabel: payload?.cancelLabel,
    });

    renderRemovalList(payload?.zones);
    showRoot();
  }

  function updateRemoval(payload) {
    removalStrings = {
      removeLabel: payload?.removeLabel || removalStrings.removeLabel,
      removeAllLabel: payload?.removeAllLabel || removalStrings.removeAllLabel,
      empty: payload?.empty || removalStrings.empty,
    };

    if (currentView !== 'removal') {
      return;
    }

    setView('removal', {
      title: payload?.title,
      confirmLabel: payload?.confirmLabel || removalStrings.removeAllLabel,
      cancelLabel: payload?.cancelLabel,
    });

    renderRemovalList(payload?.zones);
    showRoot();
  }

  function removeZone(id) {
    if (id === undefined || id === null) return;
    hideRoot();
    fetch(`https://${resource}/remove`, {
      method: 'POST',
      body: JSON.stringify({ id }),
    });
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
    if (!els.textUIColor.value.startsWith('#')) {
      els.textUIColor.value = `#${els.textUIColor.value.replace(/[^0-9a-fA-F]/g, '')}`;
    }
  });

  // Buttons
  els.cancelBtn.addEventListener('click', () => closeUI());
  els.confirmBtn.addEventListener('click', () => {
    if (currentView === 'designer') {
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
      hideRoot();
      fetch(`https://${resource}/confirm`, { method: 'POST', body: JSON.stringify(data) });
    } else {
      if (els.confirmBtn.disabled) return;
      hideRoot();
      fetch(`https://${resource}/removeAll`, { method: 'POST', body: '{}' });
    }
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
    const { action, data, meta } = event.data;
    if (action === 'open') openDesigner(data || {}, meta || {});
    else if (action === 'openRemoval') openRemoval(data || {});
    else if (action === 'updateRemoval') updateRemoval(data || {});
    else if (action === 'close') hideRoot();
  });

  // Close by default on load
  hideRoot();
})();
