FROM liabifano/executor:bd0ce94

COPY setup.py /job-python-skeleton/
COPY requirements.txt /job-python-skeleton/
COPY src/ /job-python-skeleton/src/

RUN find . | grep -E "(__pycache__|\.pyc$)" | xargs rm -rf
RUN pip install -U -r job-python-skeleton/requirements.txt
RUN pip install job-python-skeleton/.
