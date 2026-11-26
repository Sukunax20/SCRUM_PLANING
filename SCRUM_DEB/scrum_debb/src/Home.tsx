import { useState } from 'react';

interface Props {
  usuario: string;
  onLogout: () => void;
}

function Home({ usuario, onLogout }: Props) {
  const [vista, setVista] = useState('Usuarios');
  const [mostrarMenu, setMostrarMenu] = useState(false);

  return (
    <div className="min-h-screen flex flex-col bg-gray-100">
      
      {/* Navbar */}
      <nav className="bg-blue-600 text-white p-4 flex justify-between items-center">
        <div className="flex items-center gap-3">
          {/* Botón para celular */}
          <button
            onClick={() => setMostrarMenu(!mostrarMenu)}
            className="md:hidden bg-blue-800 px-3 py-1 rounded"
          >
            Menu
          </button>
          <h1 className="text-xl font-bold">Sistema SCRUM</h1>
        </div>

        <div className="flex items-center gap-3">
          <span className="text-sm">Usuario: {usuario}</span>
          <button
            onClick={onLogout}
            className="bg-red-500 px-3 py-1 rounded text-sm hover:bg-red-600"
          >
            Salir
          </button>
        </div>
      </nav>

      {/* Contenedor principal */}
      <div className="flex flex-1 flex-col md:flex-row">
        
        {/* Sidebar */}
        <aside className={`${mostrarMenu ? 'block' : 'hidden'} md:block w-full md:w-60 bg-gray-200 p-4`}>
          <p className="font-bold text-gray-700 mb-3">Opciones</p>
          
          <div className="flex flex-col gap-2">
            <button
              onClick={() => { setVista('Usuarios'); setMostrarMenu(false); }}
              className={`p-2 text-left rounded ${vista === 'Usuarios' ? 'bg-blue-600 text-white' : 'bg-white text-gray-800'}`}
            >
              Usuarios
            </button>

            <button
              onClick={() => { setVista('Tareas'); setMostrarMenu(false); }}
              className={`p-2 text-left rounded ${vista === 'Tareas' ? 'bg-blue-600 text-white' : 'bg-white text-gray-800'}`}
            >
              Tareas
            </button>

            <button
              onClick={() => { setVista('Iniciativas'); setMostrarMenu(false); }}
              className={`p-2 text-left rounded ${vista === 'Iniciativas' ? 'bg-blue-600 text-white' : 'bg-white text-gray-800'}`}
            >
              Iniciativas
            </button>
          </div>
        </aside>

        {/* Contenido dinámico */}
        <main className="flex-1 p-5">
          
          {/* Indicador de ubicación */}
          <div className="bg-white p-3 mb-4 border border-gray-300 rounded">
            <p className="text-sm text-gray-600">
              Estás en: <b>Home / {vista}</b>
            </p>
          </div>

          {/* Caja donde carga cada sección */}
          <div className="bg-white p-5 border border-gray-300 rounded">
            {vista === 'Usuarios' && (
              <div>
                <h2 className="text-xl font-bold mb-3">Sección de Usuarios</h2>
                <p className="mb-2">Aquí se muestran los usuarios del proyecto:</p>
                <ul className="list-disc pl-5">
                  <li>Elkin Mosquera - Admin</li>
                  <li>Carlos Pérez - Estudiante</li>
                  <li>María López - Estudiante</li>
                </ul>
              </div>
            )}

            {vista === 'Tareas' && (
              <div>
                <h2 className="text-xl font-bold mb-3">Sección de Tareas</h2>
                <p className="mb-2">Tareas asignadas:</p>
                <ul className="list-disc pl-5">
                  <li>Hacer el login (Listo)</li>
                  <li>Hacer el navbar y sidebar (En proceso)</li>
                  <li>Subir tarea al foro (Pendiente)</li>
                </ul>
              </div>
            )}

            {vista === 'Iniciativas' && (
              <div>
                <h2 className="text-xl font-bold mb-3">Sección de Iniciativas</h2>
                <p className="mb-2">Ideas propuestas para mejorar la app:</p>
                <ul className="list-disc pl-5">
                  <li>Agregar modo oscuro</li>
                  <li>Conectar a una base de datos</li>
                </ul>
              </div>
            )}
          </div>

        </main>
      </div>

    </div>
  );
}

export default Home;
