# AUTHOR:           Brian Ball
# DESCRIPTION:      OpenStudio / Jupyter notebook Docker Container
#
#  docker build . -t='os-jupyter'
#  docker run -it -p 8888:8888 os-jupyter
#
#  JupyterLab application directory is  /usr/local/share/jupyter/lab

#may include suffix
ARG OPENSTUDIO_VERSION=3.6.1
FROM nrel/openstudio:3.6.1 as base
MAINTAINER Brian Ball brian.ball@nrel.gov

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y upgrade && apt-get install -y \
  ca-certificates \
  emacs \
  git \
  locales \
  locales-all \
  python3-dev \
  python3-pip \
  jupyter \
  sudo
  
RUN ln -s /usr/bin/python3 /usr/bin/python
  
RUN pip3 install --upgrade pip
RUN pip3 install virtualenv
RUN pip3 install --ignore-installed pyzmq terminado 
RUN pip3 install jupyterlab

RUN gem install czmq-ffi-gen -v 1.0.0 && \
    gem install cztop -v 1.0.0 && \
    gem install iruby rest-client open-uri && \
    iruby register --force

#install OpenStudio-server
RUN cd /opt && \
    mkdir OpenStudio-server && \
    cd OpenStudio-server && \
    git clone https://github.com/NREL/OpenStudio-server.git . && \
    cd bin && \
    /opt/OpenStudio-server/bin/openstudio_meta install_gems

#install URBANopt
RUN gem install urbanopt-cli rubyzip

#install OpenStudio-analysis-gem
#RUN cd /opt && \
#    mkdir OpenStudio-analysis-gem && \
#    cd OpenStudio-analysis-gem && \
#    git clone https://github.com/NREL/OpenStudio-analysis-gem.git . && \
#    git checkout develop && \
#    bundle install && \
#    gem build openstudio-analysis.gemspec && \
#    gem install --local ./openstudio-analysis-1.3.0.gem
RUN gem install nokogiri -v 1.11.7
RUN gem install openstudio-analysis
        
#install OpenStudio Measure Gems
RUN gem install openstudio-calibration
RUN gem install openstudio-common-measures    

WORKDIR /examples
RUN mkdir /examples/notebooks

#copy notebooks over and set permissions
COPY ./notebooks/submit_single_run.ipynb /examples/notebooks/submit_single_run.ipynb
COPY ./notebooks/submit_URBANopt.ipynb /examples/notebooks/submit_URBANopt.ipynb
COPY ./notebooks/create_URBANopt.ipynb /examples/notebooks/create_URBANopt.ipynb
COPY ./notebooks/create_URBANopt_OSA.ipynb /examples/notebooks/create_URBANopt_OSA.ipynb
COPY ./notebooks/URBANopt_template.json /examples/notebooks/URBANopt_template.json
COPY ./osw_project /examples/notebooks

#trust all notebooks
RUN find /examples/notebooks -name '*.ipynb' -exec jupyter trust {} \;

#set version
COPY version.txt /app/version.txt

RUN VERSION=$(cat /app/version.txt | tr -d '\r\n') && \
    echo "export VERSION=$VERSION" >> /etc/profile

# Set the environment variable using the ENTRYPOINT command
ENTRYPOINT ["/bin/sh", "-c", ". /etc/profile && exec \"$@\"", "--"]

EXPOSE 8888
CMD ["jupyter-lab", "--ip=0.0.0.0","--port=8888" ,"--no-browser", "--allow-root", "--LabApp.token=''"]