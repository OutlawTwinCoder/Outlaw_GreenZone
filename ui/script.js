const resource = window.GetParentResourceName ? window.GetParentResourceName() : 'Outlaw_GreenZone';
const root = document.getElementById('app');
const form = document.getElementById('designer-form');
const colorHex = document.getElementById('bannerColorText');
const colorPicker = document.getElementById('bannerColor');
const radiusSlider = document.getElementById('radius');
const speedSlider = document.getElementById('speedLimit');
const radiusValue = document.getElementById('radius-value');
const radiusSuffix = document.getElementById('radius-suffix');
const speedValue = document.getElementById('speed-value');
const cancelBtn = document.getElementById('cancel');
const confirmBtn = document.getElementById('confirm');
const bannerPosition = document.getElementById('bannerPosition');

let labels = null;
let defaults = null;
let open = false;

function clamp(val, min, max) {
    return Math.min(Math.max(val, min), max);
}

function formatSpeed(value) {
    if (!labels) return `${value}`;
    if (Number(value) <= 0) {
        return labels.helpers.unlimited;
    }

    return `${value} ${labels.helpers.speedUnit}`;
}

function applyLabels() {
    document.getElementById('title').textContent = labels.title;
    document.getElementById('subtitle').textContent = labels.subtitle;

    cancelBtn.textContent = labels.actions.cancel;
    confirmBtn.textContent = labels.actions.confirm;

    Object.entries(labels.fields).forEach(([key, field]) => {
        const label = document.getElementById(`label-${key}`);
        const hint = document.getElementById(`hint-${key}`);
        if (label) {
            label.textContent = field.label || '';
        }
        if (hint) {
            hint.textContent = field.description || '';
        }
        const input = document.getElementById(key);
        if (input && field.placeholder) {
            input.placeholder = field.placeholder;
        }
    });

    radiusSuffix.textContent = labels.helpers.radiusSuffix;

    bannerPosition.innerHTML = '';
    labels.positions.forEach((option) => {
        const element = document.createElement('option');
        element.value = option.value;
        element.textContent = option.label;
        bannerPosition.appendChild(element);
    });
}

function applyDefaults() {
    document.getElementById('blipName').value = defaults.blipName || '';
    document.getElementById('banner').value = defaults.banner || '';
    document.getElementById('bannerColor').value = defaults.bannerColor || '#ff5a47';
    document.getElementById('bannerColorText').value = (defaults.bannerColor || '#ff5a47').toUpperCase();
    document.getElementById('bannerPosition').value = defaults.bannerPosition || 'top-center';
    document.getElementById('disableFiring').checked = Boolean(defaults.disableFiring);
    document.getElementById('invincible').checked = Boolean(defaults.invincible);

    radiusSlider.value = clamp(Number(defaults.radius || 10), 1, 100);
    speedSlider.value = clamp(Number(defaults.speedLimit || 0), 0, 120);
    document.getElementById('blipID').value = Number(defaults.blipID || 487);
    document.getElementById('blipColor').value = Number(defaults.blipColor || 1);

    radiusValue.textContent = radiusSlider.value;
    speedValue.textContent = formatSpeed(speedSlider.value);
}

function openDesigner(payload) {
    labels = payload.labels;
    defaults = payload.defaults;
    if (payload.lang) {
        document.documentElement.lang = payload.lang;
    }

    applyLabels();
    applyDefaults();

    root.classList.remove('designer--hidden');
    open = true;
}

function closeDesigner() {
    root.classList.add('designer--hidden');
    open = false;
}

function post(action, data = {}) {
    fetch(`https://${resource}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data),
    }).catch(() => {});
}

window.addEventListener('message', (event) => {
    if (!event.data || !event.data.action) return;

    if (event.data.action === 'open') {
        openDesigner(event.data);
    }

    if (event.data.action === 'close') {
        closeDesigner();
    }
});

function syncColorInputs(source) {
    if (source === 'picker') {
        colorHex.value = colorPicker.value.toUpperCase();
    } else {
        let value = colorHex.value.trim();
        if (!value.startsWith('#')) value = `#${value}`;
        if (/^#([0-9a-fA-F]{6})$/.test(value)) {
            colorPicker.value = value.toUpperCase();
            colorHex.value = value.toUpperCase();
        }
    }
}

colorPicker.addEventListener('input', () => syncColorInputs('picker'));
colorHex.addEventListener('input', () => syncColorInputs('text'));

radiusSlider.addEventListener('input', () => {
    radiusValue.textContent = radiusSlider.value;
});

speedSlider.addEventListener('input', () => {
    speedValue.textContent = formatSpeed(speedSlider.value);
});

cancelBtn.addEventListener('click', () => {
    closeDesigner();
    post('designerCancel');
});

form.addEventListener('submit', (event) => {
    event.preventDefault();
    closeDesigner();
    const data = {
        blipName: document.getElementById('blipName').value,
        banner: document.getElementById('banner').value,
        bannerColor: document.getElementById('bannerColor').value,
        bannerPosition: document.getElementById('bannerPosition').value,
        radius: radiusSlider.value,
        disableFiring: document.getElementById('disableFiring').checked,
        invincible: document.getElementById('invincible').checked,
        speedLimit: speedSlider.value,
        blipID: document.getElementById('blipID').value,
        blipColor: document.getElementById('blipColor').value,
    };

    post('designerSubmit', data);
});

window.addEventListener('keydown', (event) => {
    if (!open) return;
    if (event.key === 'Escape') {
        closeDesigner();
        post('designerEscape');
    }
});

closeDesigner();
