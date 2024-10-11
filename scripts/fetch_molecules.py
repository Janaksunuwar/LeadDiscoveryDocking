import requests

def fetch_from_zinc():
    url = "https://zinc15.docking.org/substances.txt?mwt=300-350&logp=-1-5&count=50"
    response = requests.get(url)
    with open("data/zinc/zinc_molecules.sdf", "w") as file:
        file.write(response.text)

def fetch_from_chembl():
    url = "https://www.ebi.ac.uk/chembl/api/data/molecule"
    params = {"molecule_properties.full_mwt__gte": 300, "molecule_properties.full_mwt__lte": 350, "limit": 50}
    response = requests.get(url, params=params)
    data = response.json()
    # Further processing to save the data

def fetch_from_pubchem():
    url = "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/aspirin/SDF"
    response = requests.get(url)
    with open("data/pubchem/pubchem_aspirin.sdf", "wb") as file:
        file.write(response.content)

# Example function call
fetch_from_zinc()
fetch_from_chembl()
fetch_from_pubchem()

