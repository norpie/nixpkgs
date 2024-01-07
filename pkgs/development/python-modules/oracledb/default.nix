{ lib
, buildPythonPackage
, cryptography
, cython_3
, fetchPypi
, pythonOlder
, setuptools
, wheel
}:

buildPythonPackage rec {
  pname = "oracledb";
  version = "2.0.0";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-+0SB560anoEhSCiiGaRbZTMB2AxaHMR+A4VxBbYa4sk=";
  };

  nativeBuildInputs = [
    cython_3
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    cryptography
  ];

  # Checks need an Oracle database
  doCheck = false;

  pythonImportsCheck = [
    "oracledb"
  ];

  meta = with lib; {
    description = "Python driver for Oracle Database";
    homepage = "https://oracle.github.io/python-oracledb";
    changelog = "https://github.com/oracle/python-oracledb/blob/v${version}/doc/src/release_notes.rst";
    license = with licenses; [ asl20 /* and or */ upl ];
    maintainers = with maintainers; [ harvidsen ];
  };
}
