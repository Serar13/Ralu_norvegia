import { useEffect, useState } from 'react';
import { listRooms, saveRoom, deleteRoom, seedDefaultRooms } from '../lib/api.js';
import { Plus, Trash, Edit, Save, Refresh } from '../components/Icons.jsx';

const EMPTY = { id: '', name: '', icon: '🧽', order: 99, tasks: [] };

export default function Rooms() {
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [rooms, setRooms] = useState([]);
  const [editing, setEditing] = useState(null); // room object or null

  async function load() {
    setLoading(true);
    setError('');
    try {
      setRooms(await listRooms());
    } catch (e) {
      setError(e.message ?? 'Kunne ikke laste rom.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function handleSeed() {
    setBusy(true);
    setError('');
    try {
      await seedDefaultRooms();
      await load();
    } catch (e) {
      setError(e.message ?? 'Seeding feilet.');
    } finally {
      setBusy(false);
    }
  }

  async function handleSave(room) {
    setBusy(true);
    setError('');
    try {
      await saveRoom(room);
      setEditing(null);
      await load();
    } catch (e) {
      setError(e.message ?? 'Lagring feilet.');
    } finally {
      setBusy(false);
    }
  }

  async function handleDelete(id) {
    if (!window.confirm('Slette dette rommet fra malbiblioteket?')) return;
    setBusy(true);
    try {
      await deleteRoom(id);
      await load();
    } catch (e) {
      setError(e.message ?? 'Sletting feilet.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <div className="section-actions">
        <p className="muted">
          Standard rom-/lokasjonsmaler. Disse brukes som utgangspunkt for nye
          hjem og ukesmaler.
        </p>
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="btn btn-ghost" onClick={load} disabled={loading || busy}>
            <Refresh width={18} height={18} /> Oppdater
          </button>
          <button className="btn btn-primary" onClick={() => setEditing({ ...EMPTY })} disabled={busy}>
            <Plus width={18} height={18} /> Nytt rom
          </button>
        </div>
      </div>

      {error && <div className="alert">{error}</div>}

      {loading ? (
        <div className="center-state">
          <div>
            <div className="spinner" />
            <p>Laster rom…</p>
          </div>
        </div>
      ) : rooms.length === 0 ? (
        <div className="card center-state">
          <div>
            <div className="empty-emoji">🏠</div>
            <p>Ingen rom-maler ennå.</p>
            <p className="muted" style={{ maxWidth: 360, margin: '6px auto 16px' }}>
              Fyll biblioteket med standardrommene fra appen (Baderom, Kjøkken,
              Soverom, Stue og barnerom, Inngang) med ett klikk.
            </p>
            <button className="btn btn-primary" onClick={handleSeed} disabled={busy}>
              <Plus width={16} height={16} /> {busy ? 'Legger til…' : 'Legg til standardrom'}
            </button>
          </div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(280px,1fr))', gap: 18 }}>
          {rooms.map((room) => (
            <div className="card card-pad" key={room.id}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 10 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <span style={{ fontSize: '1.7rem' }}>{room.icon}</span>
                  <div>
                    <div style={{ fontWeight: 600, fontSize: '1.05rem' }}>{room.name}</div>
                    <div className="muted" style={{ fontSize: '0.82rem' }}>
                      #{room.order} · {room.tasks.length} standardoppgave(r)
                    </div>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 6 }}>
                  <button className="icon-btn" title="Rediger" onClick={() => setEditing(room)}>
                    <Edit width={16} height={16} />
                  </button>
                  <button className="icon-btn danger" title="Slett" onClick={() => handleDelete(room.id)}>
                    <Trash width={16} height={16} />
                  </button>
                </div>
              </div>
              {room.tasks.length > 0 && (
                <ul style={{ marginTop: 14, display: 'flex', flexDirection: 'column', gap: 6 }}>
                  {room.tasks.slice(0, 4).map((t, i) => (
                    <li key={i} className="muted" style={{ fontSize: '0.85rem', display: 'flex', gap: 8 }}>
                      <span style={{ color: 'var(--teal)' }}>•</span> {t}
                    </li>
                  ))}
                  {room.tasks.length > 4 && (
                    <li className="muted" style={{ fontSize: '0.82rem' }}>
                      +{room.tasks.length - 4} flere…
                    </li>
                  )}
                </ul>
              )}
            </div>
          ))}
        </div>
      )}

      {editing && (
        <RoomModal
          initial={editing}
          busy={busy}
          onClose={() => setEditing(null)}
          onSave={handleSave}
        />
      )}
    </>
  );
}

function RoomModal({ initial, busy, onClose, onSave }) {
  const [name, setName] = useState(initial.name);
  const [icon, setIcon] = useState(initial.icon);
  const [order, setOrder] = useState(initial.order);
  const [tasksText, setTasksText] = useState(initial.tasks.join('\n'));

  function submit() {
    onSave({
      id: initial.id,
      name: name.trim(),
      icon: icon.trim() || '🧽',
      order: Number(order) || 99,
      tasks: tasksText.split('\n').map((t) => t.trim()).filter(Boolean),
    });
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h3>{initial.id ? 'Rediger rom' : 'Nytt rom'}</h3>
        <p className="muted" style={{ marginBottom: 18 }}>Definer navn, ikon og standardoppgaver.</p>

        <div style={{ display: 'flex', gap: 12 }}>
          <div className="field" style={{ flex: '0 0 80px' }}>
            <label>Ikon</label>
            <input className="input" value={icon} onChange={(e) => setIcon(e.target.value)} style={{ textAlign: 'center' }} />
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label>Navn</label>
            <input className="input" value={name} onChange={(e) => setName(e.target.value)} placeholder="Baderom" />
          </div>
          <div className="field" style={{ flex: '0 0 80px' }}>
            <label>Rekkef.</label>
            <input className="input" type="number" value={order} onChange={(e) => setOrder(e.target.value)} />
          </div>
        </div>

        <div className="field">
          <label>Standardoppgaver (én per linje)</label>
          <textarea
            className="input"
            rows={6}
            value={tasksText}
            onChange={(e) => setTasksText(e.target.value)}
            placeholder={'fei/støvsug/mopp gulvet\nrydd benkeplater\n…'}
            style={{ resize: 'vertical', lineHeight: 1.6 }}
          />
        </div>

        <div className="modal-actions">
          <button className="btn btn-ghost" onClick={onClose}>Avbryt</button>
          <button className="btn btn-primary" onClick={submit} disabled={!name.trim() || busy}>
            <Save width={16} height={16} /> {busy ? 'Lagrer…' : 'Lagre rom'}
          </button>
        </div>
      </div>
    </div>
  );
}
