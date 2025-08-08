# Proyecto Conjunto con Submódulos

Este repositorio contiene dos submódulos de Git que corresponden a proyectos independientes:

- [`integrative_project_U3_DB`](https://github.com/IMarcusDev/integrative_project_U3_DB)
- [`API-BANCO-PICHINCHA`](https://github.com/Juangranda3424/API-BANCO-PICHINCHA)

## 📥 Clonar con submódulos

Cuando este repositorio se clona de forma normal, los submódulos **no descargan su contenido automáticamente**.  
Para obtenerlos, tienes dos opciones:

### Opción 1: Clonar todo de una sola vez
```bash
git clone --recurse-submodules <URL_DEL_REPO_PRINCIPAL>
```
### Opción 2: Inicializar los submódulos después de clonar
Si ya clonaste el repositorio sin submódulos:
```bash
git submodule update --init --recursive
```
## 🔄 Actualizar submódulos
Si quieres traer los últimos cambios de cada submódulo:
```bash
git submodule update --remote --merge
```

💡 Recomendación: Si no estás familiarizado con submódulos, revisa la documentación oficial de Git sobre submódulos.
