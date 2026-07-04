import { useEffect, useState } from 'react';
import { getTemplateDay, saveTemplateDay } from '../lib/api.js';
import { WEEK_KEYS, DAY_KEYS, DEFAULT_ROOMS } from '../lib/constants.js';
import { Plus, Trash, Save, Check } from '../components/Icons.jsx';

const roomEmoji = (name) =>
  DEFAULT_ROOMS.find((r) => r.name.toLowerCase() === name.toLowerCase())?.icon ?? '🧽';

export default function TaskTemplates() {
  const [week, setWeek] = useState(WEEK_KEYS[0]);
  const [day, setDay] = useState(DAY_KEYS[0]);

  const [rooms, setRooms] = useState({}); // { roomName: [task, ...] }
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [dirty, setDirty] = useState(false);
  const [error, setError] = useState('');
  const [saved, setSaved] = useState(false);
  const [showAddRoom, setShowAddRoom] = useState(false);

  useEffect(() => {
    let alive = true;
    setLoading(true);
    setError('');
    setSaved(false);
    getTemplateDay(week, day)
      .then((data) => {
        if (!alive) return;
        setRooms(data);
        setDirty(false);
      })
      .catch((e) => alive && setError(e.message ?? 'Kunne ikke laste malen.'))
      .finally(() => alive && setLoading(false));
    return () => {
      alive = false;
    };
  }, [week, day]);

  function mutate(updater) {
    setRooms((prev) => {
      const next = updater(structuredClone(prev));
      return next;
    });
    setDirty(true);
    setSaved(false);
  }

  const updateTask = (room, idx, value) =>
    mutate((r) => {
      r[room][idx] = value;
      return r;
    });

  const addTask = (room) =>
    mutate((r) => {
      r[room] = [...(r[room] ?? []), ''];
      return r;
    });

  const deleteTask = (room, idx) =>
    mutate((r) => {
      r[room].splice(idx, 1);
      return r;
    });

  const deleteRoom = (room) =>
    mutate((r) => {
      delete r[room];
      return r;
    });

  const addRoom = (name, seedTasks = []) => {
    setShowAddRoom(false);
    if (!name) return;
    mutate((r) => {
      if (!r[name]) r[name] = [...seedTasks];
      return r;
    });
  };

  async function handleSave() {
    setSaving(true);
    setError('');
    try {
      // Drop blank task strings before persisting.
      const cleaned = {};
      for (const [room, tasks] of Object.entries(rooms)) {
        cleaned[room] = tasks.map((t) => t.trim()).filter(Boolean);
      }
      await saveTemplateDay(week, day, cleaned);
      setRooms(cleaned);
      setDirty(false);
      setSaved(true);
    } catch (e) {
      setError(e.message ?? 'Lagring feilet.');
    } finally {
      setSaving(false);
    }
  }

  const roomNames = Object.keys(rooms);

  return (
    <>
      <div className="editor-toolbar">
        <div className="chip-row" role="tablist" aria-label="Velg uke">
          {WEEK_KEYS.map((w) => (
            <button
              key={w}
              className={`chip ${w === week ? 'active' : ''}`}
              onClick={() => setWeek(w)}
            >
              {w}
            </button>
          ))}
        </div>
      </div>

      <div className="editor-toolbar">
        <div className="chip-row" aria-label="Velg dag">
          {DAY_KEYS.map((d) => (
            <button
              key={d}
              className={`chip ${d === day ? 'active' : ''}`}
              onClick={() => setDay(d)}
            >
              {d}
            </button>
          ))}
        </div>
      </div>

      <div className="section-actions">
        <p className="muted">
          Redigerer <strong>{week}</strong> · <strong>{day}</strong>. Endringer klones
          automatisk til brukere som starter denne uken.
        </p>
        <button className="btn btn-ghost" onClick={() => setShowAddRoom(true)}>
          <Plus width={18} height={18} /> Legg til rom
        </button>
      </div>

      {saved && (
        <div className="alert" style={{ background: 'rgba(63,158,139,.12)', color: 'var(--ok)', borderColor: 'rgba(63,158,139,.25)' }}>
          <Check width={16} height={16} /> Malen for {week} · {day} er lagret.
        </div>
      )}
      {error && <div className="alert">{error}</div>}

      {loading ? (
        <div className="center-state">
          <div>
            <div className="spinner" />
            <p>Laster mal…</p>
          </div>
        </div>
      ) : roomNames.length === 0 ? (
        <div className="card center-state">
          <div>
            <div className="empty-emoji">🗒️</div>
            <p>Ingen rom konfigurert for {day} ennå.</p>
            <button className="btn btn-primary btn-sm" style={{ marginTop: 12 }} onClick={() => setShowAddRoom(true)}>
              <Plus width={16} height={16} /> Legg til første rom
            </button>
          </div>
        </div>
      ) : (
        roomNames.map((room) => (
          <div className="room-block" key={room}>
            <div className="room-head">
              <div className="room-title">
                <span className="emoji">{roomEmoji(room)}</span>
                {room}
                <span className="muted" style={{ fontWeight: 400 }}>
                  · {rooms[room].length} oppgave(r)
                </span>
              </div>
              <button className="icon-btn danger" title="Fjern rom" onClick={() => deleteRoom(room)}>
                <Trash width={17} height={17} />
              </button>
            </div>
            <div className="task-list">
              {rooms[room].map((task, idx) => (
                <div className="task-item" key={idx}>
                  <span className="drag">⋮⋮</span>
                  <input
                    className="t-input"
                    value={task}
                    placeholder="Beskriv oppgaven…"
                    onChange={(e) => updateTask(room, idx, e.target.value)}
                  />
                  <button
                    className="icon-btn danger"
                    title="Slett oppgave"
                    onClick={() => deleteTask(room, idx)}
                  >
                    <Trash width={16} height={16} />
                  </button>
                </div>
              ))}
              <div className="add-task-row">
                <button className="btn btn-ghost btn-sm" onClick={() => addTask(room)}>
                  <Plus width={16} height={16} /> Legg til oppgave
                </button>
              </div>
            </div>
          </div>
        ))
      )}

      {dirty && (
        <div className="dirty-bar">
          <span>Du har ulagrede endringer i {week} · {day}.</span>
          <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
            <Save width={18} height={18} /> {saving ? 'Lagrer…' : 'Lagre mal'}
          </button>
        </div>
      )}

      {showAddRoom && (
        <AddRoomModal
          existing={roomNames}
          onClose={() => setShowAddRoom(false)}
          onAdd={addRoom}
        />
      )}
    </>
  );
}

function AddRoomModal({ existing, onClose, onAdd }) {
  const [custom, setCustom] = useState('');
  const available = DEFAULT_ROOMS.filter((r) => !existing.includes(r.name));

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h3>Legg til rom</h3>
        <p className="muted" style={{ marginBottom: 16 }}>
          Velg en standardmal (med forhåndsutfylte oppgaver) eller lag et eget rom.
        </p>

        {available.length > 0 && (
          <>
            <label className="muted" style={{ fontSize: '0.82rem', fontWeight: 500 }}>Standardrom</label>
            <div className="chip-row" style={{ margin: '8px 0 18px' }}>
              {available.map((r) => (
                <button
                  key={r.id}
                  className="chip"
                  onClick={() => onAdd(r.name, r.tasks)}
                >
                  {r.icon} {r.name}
                </button>
              ))}
            </div>
          </>
        )}

        <div className="field">
          <label htmlFor="customRoom">Eget rom</label>
          <input
            id="customRoom"
            className="input"
            placeholder="F.eks. Vaskerom"
            value={custom}
            onChange={(e) => setCustom(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && onAdd(custom.trim())}
          />
        </div>

        <div className="modal-actions">
          <button className="btn btn-ghost" onClick={onClose}>Avbryt</button>
          <button
            className="btn btn-primary"
            disabled={!custom.trim() || existing.includes(custom.trim())}
            onClick={() => onAdd(custom.trim())}
          >
            <Plus width={16} height={16} /> Legg til
          </button>
        </div>
      </div>
    </div>
  );
}
